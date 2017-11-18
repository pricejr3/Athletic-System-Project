# README #

### What is this repository for? ###

This repository houses the Miami Univesity Athletic Medical Records System. The master branch of this repository contains the original code of the system and each other branch corresponds to an update to the system.

### System Notes ###

* The address of test server that this repository is located on is 172.17.31.167
* The system on the test server is located in the /usr/local/musm directory
* To access the test database use the command: psql musmdb musmdb_admin

### Repository Notes ###

* **Always** Pull before committing local changes
* There are two versions of this repository: your local copy that you cloned and the copy that's on the server
* **Always** make changes to your local copy, never the copy on the server
* **Always** make changes on your local copy in the proper branch
* Each patch or requirement has its own branch
* To change branches on your local copy, use the command: git checkout name_of_branch
* **Always** pull after changing branches (though most tasks are only assigned to on person; in other words, this is not always necessary on the local copy)
* To pull changes from the branch, use the command: git pull
* Once you have changes to commit and push to the repository, use the command: git commit -m "message_here"
* Once your changes are successfully committed to the repository, use the command: git push
* Once you are ready to test your changes on the server log onto the server and change the server's branch.
* **Always** make sure nobody else is testing on the server before changing its branch
* To change the server's branch, use the command: sudo git checkout name_of_branch
* Again, **always** pull after changing branches
* To pull your changes on the server, use the command: sudo git pull
* Now the server should be all ready for you to test your patch on!