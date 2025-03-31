## What's this?

This is a fast, simple and clean install for Moodle with docker in few steps. 

## Demonstration

![Demo](demo.gif)

This gif is demonstration only, it cannot be used as guide.

## Customize

The Moodle current version is the 4.5 but you can customize it if do you want in your `Dockerfile`.

Supported:

- Apache
- Nginx
- MySQL
- Postgres

## Requirements

- Ubuntu 22.04
- Ask to install in Windows if needed

## Configuring

- Create your `.env` based in `.env.example` file
- Change the passwords that are exposed in this git repository.

## Usage

### Building the image

If do you want to use my image `antonio24073/moodle:4.5-apache` you can put it in the `.env` and jump this step.

```bash
make build
```


### Creating the volume folder

```bash
make run
make mkdir
make rm
```

### Running docker compose

```bash
make up
```

### Add (production) linux permissions

```bash
make perm
```

### Add (developer) linux permissions

Don't jump this step, because you will need to edit the `config.php` file

```bash
make perm_dev
```

Change this back if you don't need to edit the files.

### Install Moodle if not installed

```bash
make install
```

### Configuring the config.php file

Go to `./vol/moodle/config.php` and change the passwords

## Access

### Running in Localhost

#### Ubuntu

Go to `/etc/hosts` and add `0.0.0.0 moodle.local` or `0.0.0.0 your.url` 

To Moodle, access this url in the browser.

To PhpMyAdmin ou PgAdmin use `your.url:8081`


## Saving the image

Create a repository in the Docker Hub.

Be careful with the visibility of the repository, whether it is public or private.

**If you do it without change the visibility in docker hub, it will be public.**

### Do the Docker Hub Login

```bash
make login
```

### Push

After build, you can push it:

```bash
make push
```
