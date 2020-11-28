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
            print(f'Цена за неделю {number_of_week} успешно установлена')

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def countries(self):
        sql = """select id, name_of_country from country"""
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
    def apartments(self, country_id=None, sort_by_id=False):
        if country_id is None and not sort_by_id:
            sql = "select id, country_id, address_of_house, description_of_house from house"
        elif country_id is None and sort_by_id:
            sql = "select id, country_id, address_of_house, description_of_house from house order by id"
        elif country_id is not None and not sort_by_id:
            sql = "select id, country_id, address_of_house, description_of_house from house where country_id = %s"
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


cherrypy.config.update({
    'server.socket_host': 'localhost',
    'server.socket_port': 8080,
})
cherrypy.quickstart(App(parse_cmd_line()))
