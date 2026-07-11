# Session storage configuration.
#
# In production, store session data in the cache (solid_cache) instead of the
# cookie. Only a small session identifier is kept in the cookie, so large
# payloads accumulated during OIDC sign-in (id_token JWT, access/refresh tokens,
# user metadata) can no longer blow past the 4KB cookie limit and raise
# ActionDispatch::Cookies::CookieOverflow. See:
# https://github.com/concerto/concerto/issues/1656
#
# Development and test intentionally keep the default cookie store: their cache
# stores (memory_store / null_store) don't durably persist session data, which
# would otherwise log users out between requests.
if Rails.env.production?
  Rails.application.config.session_store :cache_store, key: "_concerto_session"
end
