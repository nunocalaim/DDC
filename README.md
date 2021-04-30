# HTTP Flask Server that saves POST requests to s3 using terraforms

In order to get started you should have an AWS account, and a pair of ssh access keys.

### Requirements:
- ```terraform```
- a file with your ssh credentials for aws called ddc.pem at ```~/.ssh/ddc.pem``` 

## Instructions:

clone this repo, cd to this repo and run
```
cd DDC/terraform
bash deploy.sh
```
It will ask you for the ssh keys or you can add them on the file prod.tfvars

Then after it finished, terraform will output the IP public address of your instance.

You need to SSH into the machine and run

```cd Setup-Flask-Machine/python_flask/```
```(nohup python3 -m tracking_server 2> /dev/null &)``` 

Then you can exit the connection, go back to your local machine and test the server and the different post requests on

http://[IP given by terraforms]:8765/ui

or alternatively you can run
```
bash test.sh [IP given by terraforms]
```
example:
```
bash test.sh 54.23.65.123
```


You can then check the s3 created bucket on your AWS account for those requests

## Additional Info

The python flask server can be found here: https://github.com/nunocalaim/Setup-Flask-Machine