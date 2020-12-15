--user_of_site  - таблица пользователей сервиса, роль потльзователя определяется в полях landlord, tenant, какая-то из них обязательно должна быть, но может быть и обе сразу
create type sex as enum ('female','male', 'None');
DROP TABLE IF EXISTS user_of_site CASCADE;
create table user_of_site (
  id serial primary key,
  name_of_user varchar(255) not null,
  surname varchar(255) not null,
  email varchar(255) unique not null,
  phone_number varchar(255) unique not null,
  gender sex not null default 'None',
  birthday date,
  photo_url varchar(255)
  -- landlord boolean not null default(false),
  -- tenant boolean not null default(false),
  -- check (landlord or tenant = true)
);


--https://gist.github.com/abroadbent/6233480
--country - справочник стран с комиссией сервиса, которая не может быть меньше 0
DROP TABLE IF EXISTS country CASCADE;
create table country(
  id serial primary key,
  name_of_country varchar(255) unique not null,
  tax integer not null check(tax >= 0)
);

--house - таблица информации о домах. Цена за аренду определяется следующим образом: арендодатель назначает постоянную цену, которая будет показана сервисом, при этом может дополнительно задать промежутки, в которых стоимость меняется и указывает её, дополнительные цены хранятся в таблице price_for_week
--Так же пользователь может указать цену за клининг
DROP TABLE IF EXISTS house CASCADE;
create table house (
  id serial primary key,
  landlord_id integer not null references user_of_site(id),
  country_id integer not null references country(id),
  address_of_house varchar(255) not null,
  longitude numeric(2) not null,
  latitude numeric(2) not null,
  description_of_house text not null,
  room_number integer not null,
  beds_number integer not null,
  max_people integer not null,
  default_price integer not null,
  cleaning_price integer,
  check (room_number > 0 and beds_number > 0 and max_people > 0),
  check (default_price > 0 and cleaning_price > 0),
  check (longitude >= -90.00 and longitude <= 90.00),
  check (latitude >= -180.00 and latitude <= 180.00)
);

--price_for_week - таблица с указанием цены за неделю, неделю обозначаем
DROP TABLE IF EXISTS price_for_week CASCADE;
create table price_for_week(
  house_id integer not null references house(id),
  price integer not null,
  number_of_week integer not null,
  check (number_of_week > 0 and number_of_week <= 53),
  check (price >= 0),
  unique (house_id, number_of_week)
  -- запись на одну и ту же неделю для одного дома должна быть уникальна
);

-- application_rent - информация о датах аренды и сатусе заявки. По дефолту заявка под рассмотрением.
create type app_status as enum ('accepted', 'declined', 'under consideration');
DROP TABLE IF EXISTS application_rent CASCADE;
create table application_rent(
  id serial primary key,
  number_of_week integer not null,
  house_id int references house(id),
  descr_of_aplication varchar(255),
  final_price integer not null,
  check (final_price > 0)
  status app_status not null default 'under consideration'
  unique (number_of_week, house_id)
);

--comfort - справочник возможных удобств 
DROP TABLE IF EXISTS comfort CASCADE;
create table comfort(
  id serial primary key,
  name_of_comfort varchar(255)
);

--comfort_with_house - таблица о возможных удобств для дома 
DROP TABLE IF EXISTS comfort_with_house CASCADE;
create table comfort_with_house (
    house_id integer not null references house(id),
    comfort_id integer not null references comfort(id),
    primary key (house_id, comfort_id)
); 

-- reviews_for_house - таблица отзыва на жилье от арендатора. evaluation, location_convenience, cleanliness, friendlines, addition_value - отзывы от 1 до 5  
DROP TABLE IF EXISTS reviews_for_house CASCADE;
create table reviews_for_house(
  id serial primary key,
  application_id integer references application_rent(id),
  evaluation smallint not null,
  location_convenience smallint not null,
  cleanliness smallint not null,
  friendliness smallint not null,
  addition_value smallint not null,
  descr text not null,
  check (addition_value >= 1 and addition_value <= 5),
  check (friendliness >= 1 and friendliness <= 5),
  check (cleanliness >= 1 and cleanliness <= 5),
  check (location_convenience >= 1 and location_convenience <= 5),
  check (evaluation >= 1 and evaluation <= 5)
);

-- reviews_for_house - отзывы на арендаторов от арендодателя. 
DROP TABLE IF EXISTS reviews_for_tenant CASCADE;
create table reviews_for_tenant(
  id serial primary key,
  application_id integer references application_rent(id),
  descr text not null,
  rating smallint not null,
  check (rating >= 1 and  rating<= 5)
);

-- genre - справочник жанров развлечений
DROP TABLE IF EXISTS genre CASCADE;
create table genre(
  id serial primary key,
  name_of_genre varchar(255) unique not null
);

-- entertainment - таблица развлечений с их местом ии датами проведения и жанром
DROP TABLE IF EXISTS entertainment CASCADE;
create table entertainment(
  id serial primary key,
  country varchar(255)not null references country(name_of_country),
  name_of_entertainment varchar(255) not null,
  longitude numeric(2) not null,
  latitude numeric(2) not null,
  datе_start date not null,
  datе_end date not null,
  genre_id integer not null references genre(id),
  check (datе_start <= datе_end)
);
