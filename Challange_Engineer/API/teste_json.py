import requests
import json

#url = 'https://api.mercadolibre.com/sites/MLA/search?q=chromecast&limit=50#json'
#url = 'https://api.mercadolibre.com/sites/MLA/search?q=AppleTV&limit=50#json'
url = 'https://api.mercadolibre.com/sites/MLA/search?q=GoogleHome&limit=50#json'

response = requests.get(url)

state = response.json()['results']

list_json = []
for i in state:
    json_final = 'title: ' + i['title'] + ', '
    json_final += 'listing_type_id: ' + i['listing_type_id'] + ', '
    json_final += 'category_id: ' + i['category_id'] + ', '
    json_final += 'domain_id: ' + i['domain_id'] + ', '
    json_final += 'thumbnail: '  + i['thumbnail'] + ', '
    json_final += 'currency_id: ' + i['currency_id'] + ', '
    json_final += 'price: ' + str(i['price'])
    list_json.append(json_final)
    
jsonFile = open("C:/Users/AU_CAMAROTTO/Downloads/googlehome.json", "w", encoding="utf-8")
jsonFile.write(jsonString)
jsonFile.close()