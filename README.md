# data.codefordc.org
The beginnings of an open source project for data.codefordc.org, which is the beginnings of a replacement for opendatadc.org.

This repository includes the CKAN theme used by data.codefordc.org as well any custom pages used by the site.

## Local development Setup Instructions

### Prerequisites
- Git
- [Docker](https://docs.docker.com/engine/installation/) for your OS.
- Python 2.7
- pip
- python-virtualenv (`pip install virtualenv`)
- Ruby 2.2.3


### Install CKAN
1. Clone this repository.
2. Run the following commands (instructions will be slightly different for other operating systems)
```
mkdir ~/ckan/lib
mkdir ~/ckan/etc
sudo ln -s /Users/{your-home}/ckan/lib /usr/local/ckan
sudo ln -s /Users/{your-home}/ckan/etc /etc/ckan
```
3. Create the virtual environment that ckan will be installed into and activate it
```
mkdir -p ~/ckan/lib/ckan/default
sudo chown 'whoami' /usr/local/ckan/default
virtualenv --not-site-packages /usr/local/ckan/default
. /usr/local/ckan/default/bin/activate
``` 
4. If no errors have occurred, your command prompt should look something like `(default) $ _`. You now need to install the 
CKAN release with `pip install -e 'git+https://github.com/ckan/ckan.git@ckan-2.5.2#egg=ckan'`
5. Install the python requirements for CKAN with `pip install -r ~/ckan/lib/default/src/ckan/requirements.txt`
6. Pause and pat yourself on the back for getting this far.
7. Open a second command prompt. (If on Windows/OSX, this should be opened through the docker quickstart terminal)
8. Run `docker-compose up` You'll see a bunch of text where the database and search engine that CKAN needs is starting up
9. Configure the `development.ini` file with your local IP (see Appendix A).
10. Run
```
mkdir -p ~/ckan/etc/default
sudo chown 'whoami' ~/ckan/etc
```
11. You'll now need to symlink the `development.ini` in this repo, into the CKAN install. It will look something like this, but the path might change.
```
sudo ln -s ~/opendatadc/development.ini /etc/ckan/default/development.ini
```
12.  Initialize the database tables, `paster db init -c /etc/ckan/default/development.ini` and you should see `Initializing DB: SUCCESS`
13. Link `who.ini`
```
ln -s /usr/local/ckan/default/src/ckan/who.ini /etc/ckan/default/who.ini`
```
14. Run `pip install ckanext-showcase && pip install -e 'git+https://github.com/ckan/ckanext-pages.git#egg=ckanext-pages'`
15. Congratulations for making it through all the instructions. Run `paster serve /etc/ckan/default/development.ini` and visit http://127.0.0.1:5000. Warning: will probably be an error page since we have not installed the opendatadc theme.


Instructions modified from [here](https://github.com/ckan/ckan/wiki/Installing-CKAN-2.2.1-on-Mac-OS-X-10.10.1).

### Install the open data dc theme (this is easier I promise)
1. Symlink the directory where this repo was cloned into the CKAN install (path might be different)
```
ln -s ~/opendatadc /usr/local/ckan/default/src/ckan/ckanext-open_data_dc
```
2. Run `paster serve /etc/ckan/default/development.ini`
3. Visit http://127.0.0.1:5000 and you should see the home page with the open data dc theme.


### Appendix A - Setting up the docker IPs
On Windows and OSX, docker-machine creates a virtual machine and will assign it a local IP address on your machine.
In most cases it will be `192.168.99.100` to double check run `docker-machine ip`.  If the output, is different please continue 
reading, otherwise no other work is needed.

On Linux, the docker daemon is running natively, so all the docker processes will be exposed on `127.0.0.1`.

1. Open `development.ini` and replace all instances of `192.168.99.100` with your modified IP (either `127.0.0.1` or the output of `docker-machine ip`).

## Local development

### Styles
SASS is used to create and maintain styles for the theme in order to compile the styles run
```
sass ckanext/open_data_dc/fanstatic/open_data_dc.scss ckanext/open_data_dc/fanstatic/open_data_dc.css 
```

### Changing templates, files, javascript
Is a very large subject and the best way to get started is to read the [CKAN documents](http://docs.ckan.org/en/latest/theming/templates.html)

## Tests
Coming soon...

Feel free to contribute here or join us on [Waffle.io](https://waffle.io/codefordc/data.codefordc.org)
