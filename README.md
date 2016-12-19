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
