#Base rocky 9.3
FROM rockylinux:9.3

#Update Package Repo
RUN yum update -y

#Install Apache
RUN yum install httpd -y

#Opening Port
EXPOSE 80/tcp

#Starting Apache
CMD /usr/sbin/httpd -D FOREGROUND
