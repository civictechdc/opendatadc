# data.codefordc.org
The beginnings of an open source project for data.codefordc.org, which is the beginnings of a replacement for opendatadc.org.

This repository includes the CKAN theme used by data.codefordc.org as well any custom pages used by the site.

## Local development Setup Instructions

### Prerequisites
- Git
- [Docker](https://docs.docker.com/engine/installation/) for your OS.

### Getting started
1. Run `git clone https://github.com/codefordc/opendatadc`
2. Navigate to `opendatadc` (where the source was just cloned into)
3. Run `docker-compose up -d`

Thats it!  CKAN and all its services are now running

### Test data
Test data and admin users can be added very easily.

1. From the directory where the source was cloned to run `docker-compose exec ckan bash`
2. Run `paster sysadmin add admin -c /etc/ckan/default/development.ini`
3. Run `paster create-test-data -c /etc/ckan/default/development.ini`

### Troubleshooting
- Known issue: CKAN starts before the postgres and solr services have finished starting up
- Solution: Run `docker-compose restart ckan`


### Appendix A - Setting up the docker IPs
On Windows and OSX, docker-machine creates a virtual machine and will assign it a local IP address on your machine.
In most cases it will be `192.168.99.100`.

On Linux, the docker daemon is running natively, so all the docker processes will be exposed on `127.0.0.1`.

## Local development
Changes to the source HTML, JS, and CSS(SCSS) files will automatically show up when the browser is reloaded.  Python changes will require the CKAN container to be restarted.  To do so run `docker-compose restart ckan`

### Styles
SASS is used to create and maintain styles for the theme in order to compile the styles run
```
sass ckanext/open_data_dc/fanstatic/open_data_dc.scss ckanext/open_data_dc/fanstatic/open_data_dc.css 
```

### Changing templates, files, javascript
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
