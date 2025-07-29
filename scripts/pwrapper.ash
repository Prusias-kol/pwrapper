script "pwrapper"
notify Coolfood;

/*
Prefernces

prusias_pwrapper_loopScript - string
prusias_pwrapper_retryAttempts - int
prusias_pwrapper_failUnsetChoices - boolean

prusias_pwrapper_logInfo - string
*/

void log_event(string event) {
    string logInfo = get_property("prusias_pwrapper_logInfo");
    if (logInfo == "") {
        set_property("prusias_pwrapper_logInfo", event + "||");
    } else {
        set_property("prusias_pwrapper_logInfo", logInfo + event + "||");
    }
}

void check_and_exit_choice() {
    string page_text = visit_url("main.php");
    string choiceAdventure = "-1";
    matcher m_choice = create_matcher( "whichchoice value=(\\d+)", page_text );
    while ( page_text.contains_text( "choice.php" ) ) {
        m_choice.reset( page_text );
        m_choice.find();
        choiceAdventure = m_choice.group( 1 );
        string choice_num = get_property( "choiceAdventure" + choiceAdventure );

        if ( choice_num == "0" ) {
            print("PWRAPPER WARN: Recommend not setting manual control for pref " + "choiceAdventure" + choiceAdventure, "yellow");
            print("Log info");
            print(get_property("prusias_pwrapper_logInfo"));
            abort( "PWRAPPER ERROR: Manual control for " + choiceAdventure);
        }
        if ( choice_num == "" ) {
            if (get_property("prusias_pwrapper_failUnsetChoices").to_boolean()) {
                print("Log info");
                print(get_property("prusias_pwrapper_logInfo"));
                abort( "PWRAPPER ERROR: Unsupported choice adventure for pref " + "choiceAdventure" + choiceAdventure);
            } else {
                print("PWRAPPER WARN: Unsupported choice adventure for pref " + "choiceAdventure" + choiceAdventure + ". Continuing.", "yellow");
                run_choice(1);
            }
            
        }

        page_text = run_choice( choice_num.to_int() );
    }
}

void check_and_exit_combat() {
    string page_text = visit_url("main.php");
    if ( page_text.contains_text( "Combat" ) ) {
        run_combat("skill saucegeyser;attack;repeat");
    }
}

boolean pwrapper() {
    // Empty log info at the start
    set_property("prusias_pwrapper_logInfo", "");
    string loopScript = get_property("prusias_pwrapper_loopScript");
    if (loopScript == "") {
        loopScript = "ploop fullday";
    }
    string retryAttemptsPref = get_property("prusias_pwrapper_retryAttempts");
    int retryAttempts = 3;
    if (retryAttemptsPref != "") {
        retryAttempts = retryAttemptsPref.to_int();
    }
    int attempts = 1;

    while (attempts <= retryAttempts) {
        print("PWRAPPER: Attempt " + attempts + " of " + retryAttempts);
        string error_msg = catch {
            cli_execute(loopScript);
        };
        if (error_msg != "") {
            print("PWRAPPER WARN: Loop script aborted with error: " + error_msg, "red");
            log_event("Attempt " + attempts + ": " + error_msg);
        }
        if (get_property('thoth19_event_list').contains_text("end")) {
            print("PWRAPPER: Loop script completed successfully.", "green");
            return true;
        } else {
            print("PWRAPPER WARN: Loop script failed. Attempting to get to safe state...", "yellow");
            log_event("Attempt " + attempts + ": " + get_property("lastMacroError") + "|" + get_property("lastEncounter") + "|" + get_property("lastCombatResult"));
            check_and_exit_choice();
            check_and_exit_combat();
            check_and_exit_choice();
            check_and_exit_combat();
            attempts += 1;
            cli_execute("uneffect beaten up");
            cli_execute("refresh all");
        }
    }

    print("PWRAPPER ERROR: Loop script failed after " + retryAttempts + " attempts.", "red");
    print("Log info");
    print(get_property("prusias_pwrapper_logInfo"));
    return false;
}

void main() {
    pwrapper();
}
