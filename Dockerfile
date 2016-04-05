FROM centos:7

MAINTAINER Horatiu Eugen Vlad "horatiu@vlad.eu"

ENV ADMIN_USER="admin" \
    ADMIN_PASS="password"

RUN yum -y install epel-release \
    && yum -y install httpd git gitweb gitolite3 \
    && yum clean all

ENV GITOLITE_HTTP_HOME=/var/lib/gitolite3

RUN sed -e "s/Listen 80.*/Listen 8080/" -i /etc/httpd/conf/httpd.conf \
    && mkdir -p ${GITOLITE_HTTP_HOME}/repositories \
    && chown apache:root -R ${GITOLITE_HTTP_HOME} \
    && chmod ug+rwx -R ${GITOLITE_HTTP_HOME} \
    && ln -s ${GITOLITE_HTTP_HOME}/repositories /var/lib/git \
    && chown apache:root /var/log/httpd \
    && chmod ug+rwx /var/log/httpd \
    && chown apache:root /run/httpd \
    && chmod ug+rwx /run/httpd

COPY git.conf /etc/httpd/conf.d/git.conf
COPY entrypoint.sh /entrypoint.sh

RUN chown apache:root /entrypoint.sh \
    && chmod ug+x /entrypoint.sh

USER apache

EXPOSE 8080

CMD [ "/entrypoint.sh" ]
