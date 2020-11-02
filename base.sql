--user_  - таблица пользователей сервиса, роль потльзователя определяется в полях landlord, tenant, какая-то из них обязательно должна быть, но может быть и обе сразу
create type sex as enum ('female','male', 'None');

DROP TABLE IF EXISTS user_ CASCADE;
create table user_ (
  id serial primary key,
  name_ varchar(255) not null,
  surname varchar(255) not null,
  email varchar(255) unique not null,
  phone_number varchar(255) unique not null,
  gender sex not null default 'None',
  bithday date,
  photo oid,
  landlord boolean not null default(false),
  tenant boolean not null default(false),
  check (landlord or tenant = true)
);


--https://gist.github.com/abroadbent/6233480
--country - справочник стран с комиссией сервиса, которая не может быть меньше 0 
DROP TABLE IF EXISTS country CASCADE;
create table country(
  name_of_country varchar(255) primary key,
  tax integer not null check(tax >= 0)
);

--house - таблица информации о домах. Цена за аренду определяется следующим образом: арендодатель назначает постоянную цену, которая будет показана сервисом, при этом может дополнительно задать промежутки, в которых стоимость меняется и указывает её, дополнительные цены хранятся в таблице price_for_week 
--Так же пользователь может указать цену за клининг   
DROP TABLE IF EXISTS house CASCADE;
create table house (
  id SERIAL primary key,
  country_name varchar(255)not null references country(name_of_country),
  adress varchar(255) not null,
  gps lseg not null,
  description_ text not null,
  room_number integer not null,
  beds_number integer not null,
  max_people integer not null,
  default_price integer not null,
  cleaning_price integer,
  check (room_number > 0 and beds_number > 0 and max_people > 0),
  check (default_price > 0 and cleaning_price > 0)
);

--price_for_week - таблица с указанием цены за неделю на определенные даты, устанавливается арендодателем
DROP TABLE IF EXISTS price_for_week CASCADE;
create table price_for_week(
  house_id integer not null references house(id),
  price integer not null,
  date_from date not null,
  date_to date not null, 
  check (date_from <= date_to and price >= 0), -- проверяем правильность дат
  unique (house_id, price, date_from, date_to) -- таким образом исключаем ситуации, когда у одного дома разная цена за один и тот же промежуток времени
);

-- application_rent - информация о датах аренды и сатусе заявки. По дефолту заявка под рассмотрением.
create type app_status as enum ('accepted', 'declined', 'under consideration');
DROP TABLE IF EXISTS application_rent CASCADE;
create table application_rent(
  id SERIAL primary key,
  date_residence_start date not null,
  date_residence_end date not null,
  house_id int references house(id),
  descr_of_aplication varchar(255),
  check (date_residence_start <= date_residence_end), -- проверяем правильность дат
  status app_status not null default 'under consideration'
);

--comfort - справочник возможных удобств 
DROP TABLE IF EXISTS comfort CASCADE;
create table comfort(
  comfort_name varchar(255) primary key
);

--comfort_with_house - таблица о возможных удобств для дома 
DROP TABLE IF EXISTS comfort_with_house CASCADE;
create table comfort_with_house (
    id_house integer not null references house(id),
    comfort varchar(255) not null references comfort(comfort_name),
    primary key (id_house, comfort)
); 

-- reviews_for_house - таблица отзыва на жилье от арендатора. estimation, location_convenience, cleanliness, friendlines, addition_value - отзывы от 1 до 5  
DROP TABLE IF EXISTS reviews_for_house CASCADE;
create table reviews_for_house(
  user_id integer references user_(id),
  house_id integer references house(id),
  application_id integer references application_rent(id),
  estimation smallint not null,
  location_convenience smallint not null,
  cleanliness smallint not null,
  friendliness smallint not null,
  addition_value smallint not null,
  descr text not null,
  check (addition_value >= 1 and addition_value <= 5),
  check (friendliness >= 1 and friendliness <= 5),
  check (cleanliness >= 1 and cleanliness <= 5),
  check (location_convenience >= 1 and location_convenience <= 5),
  check (estimation >= 1 and estimation <= 5)
);

-- reviews_for_house - отзывы на арендаторов от арендодателя. 
DROP TABLE IF EXISTS reviews_for_tenant CASCADE;
create table reviews_for_tenant(
  landlord_id integer references user_(id),
  tenant_id integer references user_(id),
  descr text not null,
  rating smallint not null,
  check (rating >= 1 and  rating<= 5)
);

-- genre - справочник жанров развлечений
DROP TABLE IF EXISTS genre CASCADE;
create table genre(
  genre_name varchar(255) not null primary key
);

-- entertainment - таблица развлечений с их местом ии датами проведения и жанром
DROP TABLE IF EXISTS entertainment CASCADE;
create table entertainment(
  id SERIAL primary key,
  country varchar(255)not null references country(name_of_country),
  name_entertainment varchar(255) not null,
  gps lseg not null,
  data_start date not null,
  data_end date not null,
  genre_name varchar(255) not null references genre(genre_name)
  check (data_start <= data_end)
);
