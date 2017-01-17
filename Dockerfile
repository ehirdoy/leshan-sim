FROM jeanblanchard/busybox-java
ADD . /demo
EXPOSE 8080
WORKDIR /demo
COPY leshan-bsserver-demo.jar /demo/
CMD ["java", "-jar", "leshan-bsserver-demo.jar"]
