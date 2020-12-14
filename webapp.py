# encoding: UTF-8
# Веб сервер
import cherrypy
import psycopg2

from connect import parse_cmd_line
from connect import create_connection
from static import index


@cherrypy.expose
class App(object):
    def __init__(self, args):
        self.args = args

    @cherrypy.expose
    def start(self):
        return "Hello web app"

    @cherrypy.expose
    def index(self):
        return index()

    @cherrypy.expose
    @cherrypy.tools.json_in()
    def register(self, name_of_user, surname, mail, phone_number, gender="None", birthday=None, photo_url=None):
        sql = ("insert into user_of_site (name_of_user, surname, email, phone_number, gender, birthday, photo_url) "
               "values (%s, %s, %s, %s, %s, %s, %s)")
        with create_connection(self.args) as db:
            cur = db.cursor()
            cur.execute(sql,
                        (name_of_user, surname, mail, phone_number, gender, birthday, photo_url))
            db.commit()
            cur.close()
            print("User added into table use_of_site")

    @cherrypy.expose
    @cherrypy.tools.json_in()
    def update_price(self, house_id, number_of_week, price):
        sql = "insert into price_for_week (house_id, number_of_week, price) values (%s, %s, %s)"
        with create_connection(self.args) as db:
            cur = db.cursor()
            cur.execute(sql, (house_id, number_of_week, price))
            db.commit()
            cur.close()
            print(f'Price by week {number_of_week} update successfully')

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def countries(self):
        sql = "select id, name_of_country from country"
        with create_connection(self.args) as db:
            cur = db.cursor()
            cur.execute(sql)
            result = []
            countries = cur.fetchall()
            for country in countries:
                result.append({"id": country[0], "name_of_country": country[1]})
            return result

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def apartments(self, country_id=None):
        if country_id is None:
            sql = "select id, country_id, address_of_house, description_of_house from house"
        else:
            sql = ("select id, country_id, address_of_house, description_of_house from house where country_id = %s"
                   " order by id")
        with create_connection(self.args) as db:
            cur = db.cursor()
            cur.execute(sql, country_id)
            result = []
            houses = cur.fetchall()
            for house in houses:
                result.append({"id": house[0], "description_of_house": house[3], "address_of_house": house[2],
                               "country_id": house[1]})
            return result

    @staticmethod
    def query_busy_houses(week):
        return f"select house_id from application_rent where " \
               f"extract(week from date_residence_start) = {week} and " \
               f"status != 'declined'"

    def get_houses_with_default_prices(self, cursor, country_id, week, bed_count):
        clause = ''
        if bed_count is not None:
            clause = ' and house.beds_number >= {bed_count}'
        sql = f"select house.id, house.description_of_house, house.beds_number, " \
              f"house.default_price + coalesce(house.cleaning_price, 0) + country.tax as price, house.landlord_id " \
              f"from house " \
              f"inner join country on country.id = house.country_id " \
              f"where " \
              f"country.id = {country_id} and " \
              f"house.id not in ({self.query_busy_houses(week)})" \
              f"{clause}"

        cursor.execute(sql)
        return [list(x) for x in cursor.fetchall()]

    @staticmethod
    def get_custom_prices(cursor, country_id, week, bed_count):
        clause = ''
        if bed_count is not None:
            clause = ' and house.beds_number >= {bed_count}'
        sql = f"select house.id, " \
              f"price_for_week.price + coalesce(house.cleaning_price, 0) + country.tax as price " \
              f"from house " \
              f"inner join price_for_week on house.id = price_for_week.house_id " \
              f"inner join country on country.id = house.country_id " \
              f"where " \
              f"price_for_week.number_of_week={week} and " \
              f"country.id = {country_id}" \
              f"{clause}"
        cursor.execute(sql)
        result = {}
        houses = cursor.fetchall()
        for house in houses:
            result[house[0]] = int(house[1])
        return result

    @staticmethod
    def replace_prices(houses, custom_prices):
        for house in houses:
            if house[0] in custom_prices:
                house[3] = custom_prices[house[0]]
        return houses

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def get_price(self, country_id, week, max_price=None, bed_count=None):
        with create_connection(self.args) as db:
            cursor = db.cursor()
            houses = self.get_houses_with_default_prices(cursor, country_id, week, bed_count)
            custom_prices = self.get_custom_prices(cursor, country_id, week, bed_count)

        houses = self.replace_prices(houses, custom_prices)
        if max_price is not None:
            houses = list(filter(lambda x: x[3] <= max_price, houses))
        prices = list(map(lambda x: x[3], houses))
        max_found_price = max(prices)
        min_found_price = min(prices)

        result = []
        for house in houses:
            result.append({"id": house[0], "apartment_name": house[1], "bed_count": house[2],
                           "week": week, "price": house[3],
                           "max_price": max_found_price, "min_price": min_found_price})
        return result

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def appt_sale(self, owner_id, country_id, week, target_plus):
        target_plus = int(target_plus)
        owner_id = int(owner_id)
        with create_connection(self.args) as db:
            cur = db.cursor()
            houses = self.get_houses_with_default_prices(cur, country_id, week, None)
            custom_prices = self.get_custom_prices(cur, country_id, week, None)

        houses = self.replace_prices(houses, custom_prices)
        houses = list(reversed(sorted(houses, key=lambda x: x[3])))
        avg = sum(map(lambda x: x[3], houses)) / len(houses)
        all_income = 0
        income_by_house = []
        i = 0
        while i < len(houses) and all_income < target_plus:
            house = houses[i]
            if house[4] != owner_id:
                continue
            price = houses[i][3] - 50
            if price <= avg:
                curr_income = price * 0.9
            else:
                curr_income = price * 0.7
            curr_income -= houses[i][3] * 0.5
            income_by_house.append(curr_income)
            all_income += curr_income
            houses[i][3] -= 50
            i += 1
        if all_income < target_plus:
            print(f"You can't reach expected profit, but you can get {all_income} profit")
        result = []
        for j in range(i):
            result.append({"apartment_id": houses[j][0], "old_price": int(houses[j][3]) + 50,
                           "new_price": houses[j][3], "expected_income": income_by_house[j]})
        return result


cherrypy.config.update({
    'server.socket_host': 'localhost',
    'server.socket_port': 8080,
})
cherrypy.quickstart(App(parse_cmd_line()))
