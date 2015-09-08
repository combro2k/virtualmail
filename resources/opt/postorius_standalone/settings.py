#-*- coding: utf-8 -*-
"""
Django settings for HyperKitty + Postorius
"""

import os

# Use SSL when logged in
USE_SSL = False

APPEND_SLASH = True

PROJECT_PATH = os.path.abspath(os.path.dirname(__file__))

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = 'change-that-at-install-time'

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = False

TEMPLATE_DEBUG = DEBUG

ADMINS = (
    ('admin', 'admin@mail.example.org'),
)

MANAGERS = ADMINS

# Hosts/domain names that are valid for this site; required if DEBUG is False
# See https://docs.djangoproject.com/en/1.5/ref/settings/#allowed-hosts
ALLOWED_HOSTS = ['*']
# And for BrowserID too, see
# http://django-browserid.rtfd.org/page/user/settings.html#django.conf.settings.BROWSERID_AUDIENCES
BROWSERID_AUDIENCES = [ "http://localhost", "http://localhost:8000" ]

# Mailman API credentials
MAILMAN_REST_SERVER = MAILMAN_API_URL = 'http://localhost:8001'
MAILMAN_USER = 'restadmin'
MAILMAN_PASS = 'restpass'
MAILMAN_API_USER = MAILMAN_USER
MAILMAN_API_PASS = MAILMAN_PASS
MAILMAN_ARCHIVER_KEY = 'SecretArchiverAPIKey'
MAILMAN_ARCHIVER_FROM = ('127.0.0.1')

# Application definition
INSTALLED_APPS = (
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.admin',
    'django.contrib.admindocs',
    'hyperkitty',
    'social.apps.django_app.default',
    'rest_framework',
    'django_gravatar',
    'crispy_forms',
    'paintstore',
    'compressor',
    'django_browserid',
    'haystack',
    'django_extensions',
    'postorius',
)

MIDDLEWARE_CLASSES = (
    'x_forwarded_for.middleware.XForwardedForMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'hyperkitty.middleware.SSLRedirect',
    'hyperkitty.middleware.TimezoneMiddleware',
)

ROOT_URLCONF = 'urls'

# CSS theme for postorius
MAILMAN_THEME = "default"

# Database
# https://docs.djangoproject.com/en/1.6/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': '/var/mailman/data/postorius.db'
    }
}

EMAIL_HOST = '127.0.0.1'
DEFAULT_FROM_EMAIL = 'admin@mail.example.org'

#USE_X_FORWARDED_HOST = False
#SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

#SESSION_COOKIE_SECURE = False
#CSRF_COOKIE_SECURE = True

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'Europe/Amsterdam'
USE_I18N = True
USE_L10N = True
USE_TZ = True

MEDIA_ROOT = ''
MEDIA_URL = ''
STATIC_ROOT = os.path.join(PROJECT_PATH, 'static/')

STATIC_URL = '/static/'

# Additional locations of static files
STATICFILES_DIRS = (
    # Put strings here, like "/home/html/static" or "C:/www/django/static".
    # Always use forward slashes, even on Windows.
    # Don't forget to use absolute paths, not relative paths.
)

STATICFILES_FINDERS = (
    'django.contrib.staticfiles.finders.FileSystemFinder',
    'django.contrib.staticfiles.finders.AppDirectoriesFinder',
#    'django.contrib.staticfiles.finders.DefaultStorageFinder',
    'compressor.finders.CompressorFinder',
)

TEMPLATE_CONTEXT_PROCESSORS = (
    "django.contrib.auth.context_processors.auth",
    "django.contrib.messages.context_processors.messages",
    "django.core.context_processors.debug",
    "django.core.context_processors.i18n",
    "django.core.context_processors.media",
    "django.core.context_processors.static",
    "django.core.context_processors.csrf",
    "django.core.context_processors.request",
    "django.core.context_processors.tz",
    "django.contrib.messages.context_processors.messages",
    "social.apps.django_app.context_processors.backends",
    "social.apps.django_app.context_processors.login_redirect",
    "hyperkitty.context_processors.export_settings",
    "hyperkitty.context_processors.postorius_info",
    "postorius.context_processors.postorius",
)

TEMPLATE_DIRS = (
    # Put strings here, like "/home/html/django_templates" or "C:/www/django/templates".
    # Always use forward slashes, even on Windows.
    # Don't forget to use absolute paths, not relative paths.
)

SESSION_SERIALIZER = 'django.contrib.sessions.serializers.PickleSerializer'

LOGIN_URL          = '/archives/accounts/login/'
LOGIN_REDIRECT_URL = '/archives/'
LOGIN_ERROR_URL    = '/archives/accounts/login/'

BROWSERID_USERNAME_ALGO = lambda email: email # Use the email as identifier
BROWSERID_VERIFY_CLASS = "django_browserid.views.Verify"

AUTHENTICATION_BACKENDS = (
        #'social.backends.open_id.OpenIdAuth',
        # http://python-social-auth.readthedocs.org/en/latest/backends/google.html
        'social.backends.google.GoogleOpenId',
        #'social.backends.google.GoogleOAuth2',
        #'social.backends.twitter.TwitterOAuth',
        'social.backends.yahoo.YahooOpenId',
        'django_browserid.auth.BrowserIDBackend',
        'django.contrib.auth.backends.ModelBackend',
)

SOCIAL_AUTH_USERNAME_IS_FULL_EMAIL = True

# http://python-social-auth.readthedocs.org/en/latest/pipeline.html#authentication-pipeline
SOCIAL_AUTH_PIPELINE = (
    'social.pipeline.social_auth.social_details',
    'social.pipeline.social_auth.social_uid',
    'social.pipeline.social_auth.auth_allowed',
    'social.pipeline.social_auth.social_user',
    'social.pipeline.user.get_username',
    # Associates the current social details with another user account with
    # a similar email address. Disabled by default, enable with care:
    # http://python-social-auth.readthedocs.org/en/latest/use_cases.html#associate-users-by-email
    #'social.pipeline.social_auth.associate_by_email',
    'social.pipeline.user.create_user',
    'social.pipeline.social_auth.associate_user',
    'social.pipeline.social_auth.load_extra_data',
    'social.pipeline.user.user_details',
)

# Gravatar base url.
GRAVATAR_URL = 'http://cdn.libravatar.org/'
GRAVATAR_SECURE_URL = 'https://seccdn.libravatar.org/'
GRAVATAR_DEFAULT_SIZE = '80'
GRAVATAR_DEFAULT_IMAGE = 'mm'
GRAVATAR_DEFAULT_RATING = 'g'
GRAVATAR_DEFAULT_SECURE = True

#
# django-compressor
# https://pypi.python.org/pypi/django_compressor
#
COMPRESS_PRECOMPILERS = (
   ('text/less', 'lessc {infile} {outfile}'),
)

COMPRESS_OFFLINE = True
# needed for debug mode
#INTERNAL_IPS = ('127.0.0.1',)

# Django Crispy Forms
CRISPY_TEMPLATE_PACK = 'bootstrap3'
CRISPY_FAIL_SILENTLY = not DEBUG

#
# Full-text search engine
#
HAYSTACK_CONNECTIONS = {
    'default': {
        'ENGINE': 'haystack.backends.whoosh_backend.WhooshEngine',
        'PATH': os.path.join("/var/mailman/hyperkitty", "fulltext_index"),
    },
}

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'filters': {
        'require_debug_false': {
            '()': 'django.utils.log.RequireDebugFalse'
        }
    },
    'handlers': {
        'mail_admins': {
            'level': 'ERROR',
            'filters': ['require_debug_false'],
            'class': 'django.utils.log.AdminEmailHandler'
        },
        'security':{
            'level': 'INFO',
            'class': 'logging.handlers.WatchedFileHandler',
            'filename': '/var/log/mailman/postorius.security.log',
            'formatter': 'verbose',
        },
        'console':{
            'level': 'DEBUG',
            'class': 'logging.StreamHandler',
            'filters': ['require_debug_false'],
            'formatter': 'simple'
        },
    },
    'loggers': {
        'django.security.DisallowedHost': {
            'handlers': ['security'],
            'propagate': False,
        },
        'django.request': {
            'handlers': ['mail_admins'],
            'level': 'ERROR',
            'propagate': False,
        },
        'hyperkitty': {
            'handlers': ['console', 'mail_admins'],
            'level': 'INFO',
        },
        'postorius': {
            'handlers': ['console', 'mail_admins'],
            'level': 'INFO',
        },
    },
    'formatters': {
        'verbose': {
            'format': '%(levelname)s %(asctime)s %(module)s %(process)d %(thread)d %(message)s'
        },
        'simple': {
            'format': '%(levelname)s %(message)s'
        },
    },
}

## Cache: use the local memcached server
#CACHES = {
#    'default': {
#        'BACKEND': 'django.core.cache.backends.memcached.PyLibMCCache',
#        'LOCATION': '127.0.0.1:11211',
#    }
#}

#
# HyperKitty-specific
#

APP_NAME = 'Mailing-list archives'

# Allow authentication with the internal user database?
# By default, only a login through Persona or your email provider is allowed.
USE_INTERNAL_AUTH = False

# Only display mailing-lists from the same virtual host as the webserver
FILTER_VHOST = False

# This is for development purposes
USE_MOCKUPS = False

try:
    from postorius_settings import *
except ImportError:
    pass