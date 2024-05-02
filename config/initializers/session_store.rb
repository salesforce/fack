Rails.application.config.session_store :cookie_store, key: '_fack_session', expire_after: 1.weeks,
                                                      secure: Rails.env.production?
