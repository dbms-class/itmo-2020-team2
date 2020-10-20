create table user (
  id serial primary key,
  name_ nvarchar(255) not null,
  sername nvarchar(255) not null,
  email nvarchar(255) unique not null,
  phone_number nvarchar(255) unique not null,
  sex enum('male', 'female', 'None') NOT NULL default 'None',
  bithday date,
  photo oid,
  landlord bit not null default(0),
  tenant bit not null default(0),
  check landlord + tenant >= 1,
  unique (phone_number, email)
)

create table house (
  id SERIAL primary key,
  country_id int foreign key references country(id),
  gps geography not null,
  description_ text not null,
  room_number integer not null (check room_number > 0),
  beds_number integer not null (check beds_number > 0),
  max_people integer not null (check max_people > 0),
  default_price integer not null (check default_price > 0),
  cleaning_price integer (check cleaning_price > 0)
)

create table price_for_week(
  house_id int foreign key references house(id),
  price integer not null (check price > 0),
  date_from data not null,
  date_to data not null, 
  check date_to > date_from,
  unique (house_id, price, date_from, date_to)
) 

create table application_rent(
  date_residence date,
  house_id int foreign key references house(id),
  descr_of_aplication text,
  status enum("declined", "under consideration", "accepted") not null default "under consideration"
)