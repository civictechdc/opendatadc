# data.codefordc.org

This repository is an open-source project for [data.codefordc.org](http://data.codefordc.org/), a [CKAN](https://ckan.org/) data portal run by [Code for DC](https://codefordc.org/).

This repository includes the CKAN theme used by data.codefordc.org as well any custom pages used by the site.

## Setup instructions

### Prerequisites

- Git
- [Docker](https://docs.docker.com/engine/installation/) for your operating system

### Cloning the repository

First, you'll need to fork this repository and clone it onto your computer. To fork it, click "Fork" in the upper-right corner of this page. You can then clone your fork using one of these two methods:
- in the terminal, navigate to whatever directory you want the repository to be cloned into and run `git clone https://github.com/<username>/opendatadc` (replace `<username>` with your GitHub username)
- inside of [GitHub Desktop](https://desktop.github.com/), go to _File > Clone Repository_ and then choose where to clone the repo to

This is the only time you will need to do this step. In future development sessions, you can just run the steps in the "Getting started" section.

### Getting started

In the terminal, navigate to `opendatadc` (or whatever directory you cloned the repository into) and run `docker-compose up -d`. Thats it! CKAN and all its services should now be running.

To view a local demo version of the site, open your favorite web browser and go to `http://localhost:5000/`. You should see a demo version of the Open Data DC site!

If the page doesn't load after a minute or so, try running `docker-compose restart ckan`. (You may be having an issue that sometimes happens where CKAN starts before the postgres and solr services have finished starting up.)

Alternatively, particularly if you are on Windows, try navigating to `192.168.99.100:5000`. (On Windows and OSX, docker-machine creates a virtual machine and will assign it a local IP address on your machine. In most cases it will be `192.168.99.100`, but you can verify this by running `docker-machine ip` in the terminal. On Linux, the docker daemon is running natively, so all the docker processes will be exposed on `127.0.0.1`.)

### Test data

Test data and admin users can be added very easily.

From the directory where the source was cloned, run `docker-compose exec ckan bash`. You should now see a promt within the terminal that begins with `/usr/lib/ckan/default/src/ckan#`.

To create a test user, run `paster sysadmin add admin -c /etc/ckan/default/development.ini`.

To create test data, run `paster create-test-data -c /etc/ckan/default/development.ini`.

To exit this prompt, run `exit`.

## Local development

Changes to the source HTML, JavaScript, and CSS/SCSS files will automatically show up when the browser is reloaded.

Changes to Python files will require the CKAN container to be restarted.  To do so run `docker-compose restart ckan`.

### Styles

SASS is used to create and maintain styles for the theme in order to compile the styles run
```
sass ckanext/open_data_dc/fanstatic/open_data_dc.scss ckanext/open_data_dc/fanstatic/open_data_dc.css 
```

### Changing templates, files, JavaScript

Is a very large subject and the best way to get started is to read the [CKAN documents](http://docs.ckan.org/en/latest/theming/templates.html)

Feel free to contribute here or join us on [Waffle.io](https://waffle.io/codefordc/data.codefordc.org)

## Deploying a new version

1. Login to the remote production machine through ssh
2. Activate the default virtualenv environment (should say (default) in terminal)
3. Navigate to `/usr/lib/ckan/default/src/ckanext-open-data-dc`
4. Grab the latest from master `git pull origin`
5. Run `python setup.py develop`
6. Run `sudo service apache2 reload`
7. Veriy [Data Portal](data.codefordc.org) is reachable and changes are there
