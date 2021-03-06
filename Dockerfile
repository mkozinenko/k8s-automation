FROM mkozinenko/jdk8:152

ARG ARTIFACT_FILENAME

EXPOSE 8080

WORKDIR /home/app

COPY ${ARTIFACT_FILENAME} .

USER app

CMD java -jar *.jar
