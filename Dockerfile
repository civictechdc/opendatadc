FROM python:2.7

RUN apt-get update
RUN apt-get install git-core redis-server -y
RUN mkdir -p /usr/lib/ckan/default
RUN chown `whoami` /usr/lib/ckan/default
RUN pip install -U setuptools
WORKDIR /usr/lib/ckan/default
RUN pip install -e 'git+https://github.com/ckan/ckan.git@ckan-2.6.0#egg=ckan'
RUN pip install --upgrade -r /usr/lib/ckan/default/src/ckan/requirements.txt
RUN mkdir -p /etc/ckan/default
RUN chown -R `whoami` /etc/ckan/
WORKDIR /usr/lib/ckan/default/src
RUN git clone https://github.com/ckan/ckanext-showcase.git
WORKDIR /usr/lib/ckan/default/src/ckanext-showcase
RUN python setup.py develop
RUN pip install -r dev-requirements.txt
WORKDIR /usr/lib/ckan/default/src
RUN git clone https://github.com/ckan/ckanext-pages.git
WORKDIR /usr/lib/ckan/default/src/ckanext-pages
RUN python setup.py develop
RUN pip install -r dev-requirements.txt
WORKDIR /usr/lib/ckan/default/src
RUN git clone https://github.com/conwetlab/ckanext-datarequests.git
WORKDIR /usr/lib/ckan/default/src//ckanext-datarequests
RUN python setup.py develop
RUN pip install -r dev-requirements.txt
WORKDIR /usr/lib/ckan/default/src
COPY . ckanext-open_data_dc/
WORKDIR /usr/lib/ckan/default/src/ckanext-open_data_dc
RUN python setup.py develop
RUN pip install -r dev-requirements.txt
COPY development.ini /etc/ckan/default/development.ini
WORKDIR /usr/lib/ckan/default/src/ckan
RUN ln -s /usr/lib/ckan/default/src/ckan/who.ini /etc/ckan/default/who.ini
WORKDIR /usr/lib/ckan/default/src/ckan

CMD paster db init -c /etc/ckan/default/development.ini && paster serve /etc/ckan/default/development.ini


EXPOSE 5000