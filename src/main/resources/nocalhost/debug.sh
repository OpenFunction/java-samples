#!/bin/bash

#mvn clean package
mvn exec:exec -Dexec.executable="java" -Dexec.args="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=5005 -jar functions-framework-invoker-1.1.0-SNAPSHOT-jar-with-dependencies.jar"