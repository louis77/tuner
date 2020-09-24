import csv

with open("world.csv") as csvfile:
    countries = csv.reader(csvfile, delimiter=',', quotechar='"')
    for row in countries:
        print(f'map["{row[1].upper()}"] = _("{row[0]}");')