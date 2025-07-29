script "pwrapper"
notify Coolfood;

/*
Prefernces

prusias_pwrapper_loopScript - string
prusias_pwrapper_retryAttempts - int
prusias_pwrapper_failUnsetChoices - boolean

_prusias_pwrapper_logInfo - string
*/

void check_and_exit_choice() {
    string page_text = to_url( place ).visit_url();
    string choiceAdventure = "-1";
    matcher m_choice = create_matcher( "whichchoice value=(\\d+)", page_text );
    while ( page_text.contains_text( "choice.php" ) ) {
        m_choice.reset( page_text );
        m_choice.find();
        choiceAdventure = m_choice.group( 1 );
        string choice_num = get_property( "choiceAdventure" + choiceAdventure );

        if ( choice_num == "0" ) {
            print("PWRAPPER: Recommend not setting manual control for pref " + "choiceAdventure" + choiceAdventure);
            print("Log info");
            print(get_property("_prusias_pwrapper_logInfo"));
            abort( "PWRAPPER ERROR: Manual control for " + choiceAdventure );
        }
        if ( choice_num == "" ) {
            if (get_property("prusias_pwrapper_failUnsetChoices").to_boolean()) {
                abort( "PWRAPPER ERROR: Unsupported choice adventure for pref " + "choiceAdventure" + choiceAdventure );
                print("Log info");
                print(get_property("_prusias_pwrapper_logInfo"));
            } else {
                print("PWRAPPER WARN: Unsupported choice adventure for pref " + "choiceAdventure" + choiceAdventure + ". Continuing.");
                run_choice("1" );
            }
            
        }

        page_text = run_choice( choice_num );
    }
}

void check_and_exit_combat() {
    string page_text = to_url( place ).visit_url();
    if ( page_text.contains_text( "Combat" ) ) {
        run_combat("skill saucegeyser;attack;repeat");
    }
}

boolean pwrapper() {
    string loopScript = getPreference("prusias_pwrapper_loopScript");
    if (loopScript == "") {
        loopScript = "ploop";
    }
    string retryAttemptsPref = getPreference("prusias_pwrapper_retryAttempts");
    int retryAttempts = 3;
    if (retryAttemptsPref != "") {
        retryAttempts = retryAttemptsPref.to_int();
    }
    int attempts = 0;

    while (attempts < retryAttempts) {
        print("PWRAPPER: Attempt " + attempt + " of " + retryAttempts);
        cli_execute(loopScript);
        if (get_property('thoth19_event_list').contains_text("end")) {
            print("PWRAPPER: Loop script completed successfully.");
            return true;
        } else {
            print("PWRAPPER WARN: Loop script failed. Attempting to get to safe state...");
            set_property("_prusias_pwrapper_logInfo", "Attempt " + attempts + ": " + get_property("lastMacroError") + "|" + get_property("lastEncounter") + "|" + get_property("lastCombatResult") + "|");
            check_and_exit_choice();
            check_and_exit_combat();
            check_and_exit_choice();
            check_and_exit_combat();
            attempts += 1;
            cli_execute("uneffect beaten up");
            cli_execute("refresh all");
        }
    }

    print("PWRAPPER ERROR: Loop script failed after " + retryAttempts + " attempts.");
    print("Log info");
    print(get_property("_prusias_pwrapper_logInfo"));
    return false;
}

void main(string input) {
    pwrapper();
}
