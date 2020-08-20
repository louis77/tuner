/*
* Copyright (c) 2020 Louis Brauer (https://github.com/louis77)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Louis Brauer <louis77@member.fsf.org>
*/

using Gee;

namespace Tuner.Model {

    public class Countries {
        
        public static HashMap<string, string> _map = null;

        public static HashMap<string, string> map {
            get {
                if (_map == null) {
                    _map = new HashMap<string, string> ();
                    _map["AF"] = _("Afghanistan");
                    _map["AX"] = _("Åland Islands");
                    _map["AL"] = _("Albania");
                    _map["DZ"] = _("Algeria");
                    _map["AS"] = _("American Samoa");
                    _map["AD"] = _("Andorra");
                    _map["AO"] = _("Angola");
                    _map["AI"] = _("Anguilla");
                    _map["AQ"] = _("Antarctica");
                    _map["AG"] = _("Antigua and Barbuda");
                    _map["AR"] = _("Argentina");
                    _map["AM"] = _("Armenia");
                    _map["AW"] = _("Aruba");
                    _map["AU"] = _("Australia");
                    _map["AT"] = _("Austria");
                    _map["AZ"] = _("Azerbaijan");
                    _map["BS"] = _("Bahamas");
                    _map["BH"] = _("Bahrain");
                    _map["BD"] = _("Bangladesh");
                    _map["BB"] = _("Barbados");
                    _map["BY"] = _("Belarus");
                    _map["BE"] = _("Belgium");
                    _map["BZ"] = _("Belize");
                    _map["BJ"] = _("Benin");
                    _map["BM"] = _("Bermuda");
                    _map["BT"] = _("Bhutan");
                    _map["BO"] = _("Bolivia");
                    _map["BQ"] = _("Bonaire, Sint Eustatius and Saba");
                    _map["BA"] = _("Bosnia and Herzegovina");
                    _map["BW"] = _("Botswana");
                    _map["BV"] = _("Bouvet Island");
                    _map["BR"] = _("Brazil");
                    _map["IO"] = _("British Indian Ocean Territory");
                    _map["BN"] = _("Brunei Darussalam");
                    _map["BG"] = _("Bulgaria");
                    _map["BF"] = _("Burkina Faso");
                    _map["BI"] = _("Burundi");
                    _map["CV"] = _("Cabo Verde");
                    _map["KH"] = _("Cambodia");
                    _map["CM"] = _("Cameroon");
                    _map["CA"] = _("Canada");
                    _map["KY"] = _("Cayman Islands");
                    _map["CF"] = _("Central African Republic");
                    _map["TD"] = _("Chad");
                    _map["CL"] = _("Chile");
                    _map["CN"] = _("China");
                    _map["CX"] = _("Christmas Island");
                    _map["CC"] = _("Cocos (Keeling) Islands");
                    _map["CO"] = _("Colombia");
                    _map["KM"] = _("Comoros");
                    _map["CG"] = _("Congo");
                    _map["CD"] = _("Congo, Democratic Republic of the");
                    _map["CK"] = _("Cook Islands");
                    _map["CR"] = _("Costa Rica");
                    _map["CI"] = _("Côte d'Ivoire");
                    _map["HR"] = _("Croatia");
                    _map["CU"] = _("Cuba");
                    _map["CW"] = _("Curaçao");
                    _map["CY"] = _("Cyprus");
                    _map["CZ"] = _("Czechia");
                    _map["DK"] = _("Denmark");
                    _map["DJ"] = _("Djibouti");
                    _map["DM"] = _("Dominica");
                    _map["DO"] = _("Dominican Republic");
                    _map["EC"] = _("Ecuador");
                    _map["EG"] = _("Egypt");
                    _map["SV"] = _("El Salvador");
                    _map["GQ"] = _("Equatorial Guinea");
                    _map["ER"] = _("Eritrea");
                    _map["EE"] = _("Estonia");
                    _map["SZ"] = _("Eswatini");
                    _map["ET"] = _("Ethiopia");
                    _map["FK"] = _("Falkland Islands (Malvinas)");
                    _map["FO"] = _("Faroe Islands");
                    _map["FJ"] = _("Fiji");
                    _map["FI"] = _("Finland");
                    _map["FR"] = _("France");
                    _map["GF"] = _("French Guiana");
                    _map["PF"] = _("French Polynesia");
                    _map["TF"] = _("French Southern Territories");
                    _map["GA"] = _("Gabon");
                    _map["GM"] = _("Gambia");
                    _map["GE"] = _("Georgia");
                    _map["DE"] = _("Germany");
                    _map["GH"] = _("Ghana");
                    _map["GI"] = _("Gibraltar");
                    _map["GR"] = _("Greece");
                    _map["GL"] = _("Greenland");
                    _map["GD"] = _("Grenada");
                    _map["GP"] = _("Guadeloupe");
                    _map["GU"] = _("Guam");
                    _map["GT"] = _("Guatemala");
                    _map["GG"] = _("Guernsey");
                    _map["GN"] = _("Guinea");
                    _map["GW"] = _("Guinea-Bissau");
                    _map["GY"] = _("Guyana");
                    _map["HT"] = _("Haiti");
                    _map["HM"] = _("Heard Island and McDonald Islands");
                    _map["VA"] = _("Holy See");
                    _map["HN"] = _("Honduras");
                    _map["HK"] = _("Hong Kong");
                    _map["HU"] = _("Hungary");
                    _map["IS"] = _("Iceland");
                    _map["IN"] = _("India");
                    _map["ID"] = _("Indonesia");
                    _map["IR"] = _("Iran");
                    _map["IQ"] = _("Iraq");
                    _map["IE"] = _("Ireland");
                    _map["IM"] = _("Isle of Man");
                    _map["IL"] = _("Israel");
                    _map["IT"] = _("Italy");
                    _map["JM"] = _("Jamaica");
                    _map["JP"] = _("Japan");
                    _map["JE"] = _("Jersey");
                    _map["JO"] = _("Jordan");
                    _map["KZ"] = _("Kazakhstan");
                    _map["KE"] = _("Kenya");
                    _map["KI"] = _("Kiribati");
                    _map["KP"] = _("Korea (Democratic People's Republic of)");
                    _map["KR"] = _("Korea, Republic of");
                    _map["KW"] = _("Kuwait");
                    _map["KG"] = _("Kyrgyzstan");
                    _map["LA"] = _("Lao People's Democratic Republic");
                    _map["LV"] = _("Latvia");
                    _map["LB"] = _("Lebanon");
                    _map["LS"] = _("Lesotho");
                    _map["LR"] = _("Liberia");
                    _map["LY"] = _("Libya");
                    _map["LI"] = _("Liechtenstein");
                    _map["LT"] = _("Lithuania");
                    _map["LU"] = _("Luxembourg");
                    _map["MO"] = _("Macao");
                    _map["MG"] = _("Madagascar");
                    _map["MW"] = _("Malawi");
                    _map["MY"] = _("Malaysia");
                    _map["MV"] = _("Maldives");
                    _map["ML"] = _("Mali");
                    _map["MT"] = _("Malta");
                    _map["MH"] = _("Marshall Islands");
                    _map["MQ"] = _("Martinique");
                    _map["MR"] = _("Mauritania");
                    _map["MU"] = _("Mauritius");
                    _map["YT"] = _("Mayotte");
                    _map["MX"] = _("Mexico");
                    _map["FM"] = _("Micronesia");
                    _map["MD"] = _("Moldova");
                    _map["MC"] = _("Monaco");
                    _map["MN"] = _("Mongolia");
                    _map["ME"] = _("Montenegro");
                    _map["MS"] = _("Montserrat");
                    _map["MA"] = _("Morocco");
                    _map["MZ"] = _("Mozambique");
                    _map["MM"] = _("Myanmar");
                    _map["NA"] = _("Namibia");
                    _map["NR"] = _("Nauru");
                    _map["NP"] = _("Nepal");
                    _map["NL"] = _("Netherlands");
                    _map["NC"] = _("New Caledonia");
                    _map["NZ"] = _("New Zealand");
                    _map["NI"] = _("Nicaragua");
                    _map["NE"] = _("Niger");
                    _map["NG"] = _("Nigeria");
                    _map["NU"] = _("Niue");
                    _map["NF"] = _("Norfolk Island");
                    _map["MK"] = _("North Macedonia");
                    _map["MP"] = _("Northern Mariana Islands");
                    _map["NO"] = _("Norway");
                    _map["OM"] = _("Oman");
                    _map["PK"] = _("Pakistan");
                    _map["PW"] = _("Palau");
                    _map["PS"] = _("Palestine");
                    _map["PA"] = _("Panama");
                    _map["PG"] = _("Papua New Guinea");
                    _map["PY"] = _("Paraguay");
                    _map["PE"] = _("Peru");
                    _map["PH"] = _("Philippines");
                    _map["PN"] = _("Pitcairn");
                    _map["PL"] = _("Poland");
                    _map["PT"] = _("Portugal");
                    _map["PR"] = _("Puerto Rico");
                    _map["QA"] = _("Qatar");
                    _map["RE"] = _("Réunion");
                    _map["RO"] = _("Romania");
                    _map["RU"] = _("Russian Federation");
                    _map["RW"] = _("Rwanda");
                    _map["BL"] = _("Saint Barthélemy");
                    _map["SH"] = _("Saint Helena, Ascension and Tristan da Cunha");
                    _map["KN"] = _("Saint Kitts and Nevis");
                    _map["LC"] = _("Saint Lucia");
                    _map["MF"] = _("Saint Martin");
                    _map["PM"] = _("Saint Pierre and Miquelon");
                    _map["VC"] = _("Saint Vincent and the Grenadines");
                    _map["WS"] = _("Samoa");
                    _map["SM"] = _("San Marino");
                    _map["ST"] = _("Sao Tome and Principe");
                    _map["SA"] = _("Saudi Arabia");
                    _map["SN"] = _("Senegal");
                    _map["RS"] = _("Serbia");
                    _map["SC"] = _("Seychelles");
                    _map["SL"] = _("Sierra Leone");
                    _map["SG"] = _("Singapore");
                    _map["SX"] = _("Sint Maarten");
                    _map["SK"] = _("Slovakia");
                    _map["SI"] = _("Slovenia");
                    _map["SB"] = _("Solomon Islands");
                    _map["SO"] = _("Somalia");
                    _map["ZA"] = _("South Africa");
                    _map["GS"] = _("South Georgia and the South Sandwich Islands");
                    _map["SS"] = _("South Sudan");
                    _map["ES"] = _("Spain");
                    _map["LK"] = _("Sri Lanka");
                    _map["SD"] = _("Sudan");
                    _map["SR"] = _("Suriname");
                    _map["SJ"] = _("Svalbard and Jan Mayen");
                    _map["SE"] = _("Sweden");
                    _map["CH"] = _("Switzerland");
                    _map["SY"] = _("Syrian Arab Republic");
                    _map["TW"] = _("Taiwan");
                    _map["TJ"] = _("Tajikistan");
                    _map["TZ"] = _("Tanzania");
                    _map["TH"] = _("Thailand");
                    _map["TL"] = _("Timor-Leste");
                    _map["TG"] = _("Togo");
                    _map["TK"] = _("Tokelau");
                    _map["TO"] = _("Tonga");
                    _map["TT"] = _("Trinidad and Tobago");
                    _map["TN"] = _("Tunisia");
                    _map["TR"] = _("Turkey");
                    _map["TM"] = _("Turkmenistan");
                    _map["TC"] = _("Turks and Caicos Islands");
                    _map["TV"] = _("Tuvalu");
                    _map["UG"] = _("Uganda");
                    _map["UA"] = _("Ukraine");
                    _map["AE"] = _("United Arab Emirates");
                    _map["GB"] = _("United Kingdom of Great Britain and Northern Ireland");
                    _map["US"] = _("United States of America");
                    _map["UM"] = _("United States Minor Outlying Islands");
                    _map["UY"] = _("Uruguay");
                    _map["UZ"] = _("Uzbekistan");
                    _map["VU"] = _("Vanuatu");
                    _map["VE"] = _("Venezuela");
                    _map["VN"] = _("Viet Nam");
                    _map["VG"] = _("Virgin Islands");
                    _map["VI"] = _("Virgin Islands");
                    _map["WF"] = _("Wallis and Futuna");
                    _map["EH"] = _("Western Sahara");
                    _map["YE"] = _("Yemen");
                    _map["ZM"] = _("Zambia");
                    _map["ZW"] = _("Zimbabwe");
                }
                return _map;
            }
        }

        public static string get_by_code(string code, string fallback = "") {
            var my_code = code.strip ();
            if (my_code == "") return fallback;
            if (map.has_key (my_code)) return map.get (my_code);
            return my_code;
        } 
   }
}
