CREATE DATABASE migrate;

CREATE TABLE properties (
    property_id integer,
    suburb TEXT,
    address VARCHAR(200),
    objective text ,
    descriptions text ,
    image_url text,
    price text ,
    bathrooms integer,
    bedrooms integer 
)

INSERT INTO properties (address, suburb) VALUES ('229 vimiera', 'marsfield')

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username TEXT,
    password_digest TEXT,
    admin boolean
)

insert into users (username, password_digest)


CREATE TABLE favourites (
    property_id integer,
    user_id integer,
    favourite_id SERIAL PRIMARY KEY
)