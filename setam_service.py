#!/usr/bin/python
# -*- coding: utf-8 -*-
from datetime import datetime
import pytz
import urllib
import re
import os

tz = str(datetime.now(pytz.timezone('Europe/Kiev')))[26:]

def prepare_tender_data(role, initial_data):
    if "tender_owner" in role:
        initial_data["data"]["assetCustodian"]["identifier"]["id"] = '01010122'
        initial_data["data"]["assetCustodian"]["identifier"]["legalName"] = u'ТОВ Орган Приватизации'
        initial_data["data"]["assetCustodian"]["name"] = u'ТОВ Орган Приватизации'
        initial_data["data"]["assetCustodian"]["contactPoint"]["name"] = u'Гоголь Микола Васильович'
        initial_data["data"]["assetCustodian"]["contactPoint"]["telephone"] = '+38(101)010-10-10'
        initial_data["data"]["assetCustodian"]["contactPoint"]["email"] = 'primatization@aditus.info'
    return initial_data


def convert_date_for_decision(date):
    date = datetime.strptime(date, '%Y-%m-%d').strftime('%d/%m/%Y')
    return date


def convert_date_for_auction(date):
    date = datetime.strptime(date, '%Y-%m-%dT%H:%M:%S.%f{}'.format(tz)).strftime('%d/%m/%Y %H:%M:%S')
    return date


def convert_duration(duration):
    if duration == u'P1M':
        duration = u'P30D'
    days = re.search('\d+D|$', duration).group()
    if len(days) > 0:
        days = days[:-1]
    return days


def adapted_dictionary(value):
    return{
        u'Класифікація згідно CAV': 'CAV',
        u'Класифікація згідно CAV-PS': 'CAV-PS',
        u'Класифікація згідно CPV': 'CPV',
        u'Аукцiон': 'active.auction',
        u'Аукціон': 'active.auction',
        u'Очiкування пропозицiй': 'active.tendering',
        u'Торги не відбулися': 'unsuccessful',
        u'Продаж завершений': 'complete',
        u'Торги скасовано': 'cancelled',
        u'Квалiфiкацiя переможця': 'active.qualification',
        u'Очікується рішення': 'pending.waiting',
        u'Очікується протокол': 'pending',
        u'Рішення скасоване': 'unsuccessful',
        u'Відмова від очікування': 'cancelled',
        u'Очікується рішення про викуп': 'pending.admission',
        u'Переможець': 'active',
        u'об’єкт реєструється': u'registering',
        u'об’єкт зареєстровано': u'complete',
        u'Об’єкт зареєстровано': u'complete',
        u'Опубліковано': u'pending',
        u'Актив завершено': u'complete',
        u'Публікація інформаційного повідомлення': u'composing',
        u'Перевірка доступності об’єкту': u'verification',
        u'lot.status.pending.deleted': u'pending.deleted',
        u'Лот видалено': u'deleted',
        u'Інформація про оприлюднення інформаційного повідомлення': u'informationDetails',
        u'об’єктів малої приватизації - аукціон': u'sellout.english',
        u'Заплановано': u'scheduled'
    }.get(value, value)


def adapting_date_for_at(field, field_value):
    field_value = adapted_dictionary(field_value)
    return field_value


def adapting_date_from_item(field, value):
    if "classification.scheme" in field:
        value = value.split(" ")[-1]
    elif "quantity" in field:
        value = float(value.replace(",","."))
    else:
        value = adapted_dictionary(value)
    return value


def download_file(url, filename, folder):
    urllib.urlretrieve(url, ('{}/{}'.format(folder, filename)))


#print(convert_date_for_auction('2018-08-21T13:33:18.171968+03:00'))







