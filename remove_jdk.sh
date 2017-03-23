#!/bin/bash
#remove jdk if exists
echo 111111
for i in $(rpm -qa | grep jdk | grep -v grep)
do
  rpm -e --nodeps $i
  echo `date +%Y-%m-%d-%T ` "--> Jdk has been uninstall." 
done

if [[ ! -z $(rpm -qa | grep jdk | grep -v grep) ]];
then
  echo `date +%Y-%m-%d-%T` "-->The system has no defult Jdk." 
fi
