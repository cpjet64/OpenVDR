use alvr_session::SessionConfig;

#[test]
fn fresh_install_does_not_enable_background_release_checks() {
    let session = SessionConfig::default();
    assert!(session
        .to_settings()
        .extra
        .new_version_popup
        .as_option()
        .is_none());
}

#[test]
fn explicit_update_check_preference_survives_save_and_load() {
    for enabled in [false, true] {
        let mut session = SessionConfig::default();
        session.session_settings.extra.new_version_popup.enabled = enabled;
        let saved = serde_json::to_vec(&session).unwrap();
        let restored: SessionConfig = serde_json::from_slice(&saved).unwrap();
        assert_eq!(
            restored
                .to_settings()
                .extra
                .new_version_popup
                .as_option()
                .is_some(),
            enabled
        );
    }
}
