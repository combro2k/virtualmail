import os
import site

# project root directory (one above `srv`)
root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))

# prepend root dir to python path
site.addsitedir(root_dir)

os.environ['DJANGO_SETTINGS_MODULE'] = 'settings'

import django.core.handlers.wsgi

application = django.core.handlers.wsgi.WSGIHandler()
