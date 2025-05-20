## What's this?

This is a fast, simple and clean install for Moodle (or Iomad) with docker in few steps.

## Demonstration

![Demo](demo.gif)

This gif is demonstration only, it cannot be used as guide.

## Customize

You can easily install **IOMAD** instead Moodle if do you want.

Supported:

- Apache
- Nginx 
- MariaDB (this repo default - recommmended here)
- MySQL
- Postgres (moodle default)

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

Enable to edition

```bash
make perm_dev
```

### Install Moodle if not installed

```bash
make install
```

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
