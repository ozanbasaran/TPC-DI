import os
import numpy as np
import pandas as pd
import xmltodict
import json

def customermgmt_convert(xml_file_path, json_output_path, csv_output_path):
    with open(xml_file_path) as fd:
        doc = xmltodict.parse(fd.read())

    with open(json_output_path, "w") as outfile:
        outfile.write(json.dumps(doc))

    f = open(json_output_path, 'r')
    cust = json.load(f)

    actions = cust['TPCDI:Actions']['TPCDI:Action']
    cust_df = pd.DataFrame(columns=['ActionType', 'ActionTS', 'C_ID', 'C_TAX_ID', 'C_GNDR', 'C_TIER', 'C_DOB',
                                    'C_L_NAME', 'C_F_NAME', 'C_M_NAME', 'C_ADLINE1', 'C_ADLINE2', 'C_ZIPCODE',
                                    'C_CITY', 'C_STATE_PROV', 'C_CTRY', 'C_PRIM_EMAIL', 'C_ALT_EMAIL',
                                    'C_PHONE_1_CTRY_CODE', 'C_PHONE_1_AREA_CODE', 'C_PHONE_1_LOCAL', 'C_PHONE_1_EXT',
                                    'C_PHONE_2_CTRY_CODE', 'C_PHONE_2_AREA_CODE', 'C_PHONE_2_LOCAL', 'C_PHONE_2_EXT',
                                    'C_PHONE_3_CTRY_CODE', 'C_PHONE_3_AREA_CODE', 'C_PHONE_3_LOCAL', 'C_PHONE_3_EXT',
                                    'C_LCL_TX_ID', 'C_NAT_TX_ID', 'CA_ID', 'CA_TAX_ST', 'CA_B_ID', 'CA_NAME'])

    for a in actions:
        cust_row = {}

        # action element
        cust_row.update({'ActionType': [f"{a.get('@ActionType')}"]})
        cust_row.update({'ActionTS': [f"{a.get('@ActionTS')}"]})

        # action.customer element
        cust_row.update({'C_ID': [f"{a.get('Customer').get('@C_ID')}"]})
        cust_row.update({'C_TAX_ID': [f"{a.get('Customer').get('@C_TAX_ID')}"]})
        cust_row.update({'C_GNDR': [f"{a.get('Customer').get('@C_GNDR')}"]})
        cust_row.update({'C_TIER': [f"{a.get('Customer').get('@C_TIER')}"]})
        cust_row.update({'C_DOB': [f"{a.get('Customer').get('@C_DOB')}"]})

        # action.customer.name element
        if a.get('Customer').get('Name') is not None:
            cust_row.update({'C_L_NAME': [f"{a.get('Customer').get('Name').get('C_L_NAME')}"]})
            cust_row.update({'C_F_NAME': [f"{a.get('Customer').get('Name').get('C_F_NAME')}"]})
            cust_row.update({'C_M_NAME': [f"{a.get('Customer').get('Name').get('C_M_NAME')}"]})
        else:
            cust_row.update({'C_L_NAME': [None]})
            cust_row.update({'C_F_NAME': [None]})
            cust_row.update({'C_M_NAME': [None]})

        # action.customer.address element
        if a.get('Customer').get('Address') is not None:
            cust_row.update({'C_ADLINE1': [f"{a.get('Customer').get('Address').get('C_ADLINE1')}"]})
            cust_row.update({'C_ADLINE2': [f"{a.get('Customer').get('Address').get('C_ADLINE2')}"]})
            cust_row.update({'C_ZIPCODE': [f"{a.get('Customer').get('Address').get('C_ZIPCODE')}"]})
            cust_row.update({'C_CITY': [f"{a.get('Customer').get('Address').get('C_CITY')}"]})
            cust_row.update({'C_STATE_PROV': [f"{a.get('Customer').get('Address').get('C_STATE_PROV')}"]})
            cust_row.update({'C_CTRY': [f"{a.get('Customer').get('Address').get('C_CTRY')}"]})
        else:
            cust_row.update({'C_ADLINE1': [None]})
            cust_row.update({'C_ADLINE2': [None]})
            cust_row.update({'C_ZIPCODE': [None]})
            cust_row.update({'C_CITY': [None]})
            cust_row.update({'C_STATE_PROV': [None]})
            cust_row.update({'C_CTRY': [None]})

        # action.customer.contactinfo element
        if a.get('Customer').get('ContactInfo') is not None:
            cust_row.update({'C_PRIM_EMAIL': [f"{a.get('Customer').get('ContactInfo').get('C_PRIM_EMAIL')}"]})
            cust_row.update({'C_ALT_EMAIL': [f"{a.get('Customer').get('ContactInfo').get('C_ALT_EMAIL')}"]})

            # action.customer.contactinfo.phone element
            # phone_1
            phone_1 = a.get('Customer').get('ContactInfo').get('C_PHONE_1', {})
            cust_row.update({'C_PHONE_1_CTRY_CODE': [f"{phone_1.get('C_CTRY_CODE')}"]})
            cust_row.update({'C_PHONE_1_AREA_CODE': [f"{phone_1.get('C_AREA_CODE')}"]})
            cust_row.update({'C_PHONE_1_LOCAL': [f"{phone_1.get('C_LOCAL')}"]})
            cust_row.update({'C_PHONE_1_EXT': [f"{phone_1.get('C_EXT')}"]})

            # phone_2
            phone_2 = a.get('Customer').get('ContactInfo').get('C_PHONE_2', {})
            cust_row.update({'C_PHONE_2_CTRY_CODE': [f"{phone_2.get('C_CTRY_CODE')}"]})
            cust_row.update({'C_PHONE_2_AREA_CODE': [f"{phone_2.get('C_AREA_CODE')}"]})
            cust_row.update({'C_PHONE_2_LOCAL': [f"{phone_2.get('C_LOCAL')}"]})
            cust_row.update({'C_PHONE_2_EXT': [f"{phone_2.get('C_EXT')}"]})

            # phone_3
            phone_3 = a.get('Customer').get('ContactInfo').get('C_PHONE_3', {})
            cust_row.update({'C_PHONE_3_CTRY_CODE': [f"{phone_3.get('C_CTRY_CODE')}"]})
            cust_row.update({'C_PHONE_3_AREA_CODE': [f"{phone_3.get('C_AREA_CODE')}"]})
            cust_row.update({'C_PHONE_3_LOCAL': [f"{phone_3.get('C_LOCAL')}"]})
            cust_row.update({'C_PHONE_3_EXT': [f"{phone_3.get('C_EXT')}"]})
        else:
            cust_row.update({'C_PRIM_EMAIL': [None]})
            cust_row.update({'C_ALT_EMAIL': [None]})
            cust_row.update({'C_PHONE_1_CTRY_CODE': [None]})
            cust_row.update({'C_PHONE_1_AREA_CODE': [None]})
            cust_row.update({'C_PHONE_1_LOCAL': [None]})
            cust_row.update({'C_PHONE_1_EXT': [None]})
            cust_row.update({'C_PHONE_2_CTRY_CODE': [None]})
            cust_row.update({'C_PHONE_2_AREA_CODE': [None]})
            cust_row.update({'C_PHONE_2_LOCAL': [None]})
            cust_row.update({'C_PHONE_2_EXT': [None]})
            cust_row.update({'C_PHONE_3_CTRY_CODE': [None]})
            cust_row.update({'C_PHONE_3_AREA_CODE': [None]})
            cust_row.update({'C_PHONE_3_LOCAL': [None]})
            cust_row.update({'C_PHONE_3_EXT': [None]})

        # action.customer.taxinfo element
        if a.get('Customer').get('TaxInfo') is not None:
            cust_row.update({'C_LCL_TX_ID': [f"{a.get('Customer').get('TaxInfo').get('C_LCL_TX_ID')}"]})
            cust_row.update({'C_NAT_TX_ID': [f"{a.get('Customer').get('TaxInfo').get('C_NAT_TX_ID')}"]})
        else:
            cust_row.update({'C_LCL_TX_ID': [None]})
            cust_row.update({'C_NAT_TX_ID': [None]})

        # action.customer.account attribute
        if a.get('Customer').get('Account') is not None:
            cust_row.update({'CA_ID': [f"{a.get('Customer').get('Account').get('@CA_ID')}"]})
            cust_row.update({'CA_TAX_ST': [f"{a.get('Customer').get('Account').get('@CA_TAX_ST')}"]})

            # action.customer.account element
            cust_row.update({'CA_B_ID': [f"{a.get('Customer').get('Account').get('CA_B_ID')}"]})
            cust_row.update({'CA_NAME': [f"{a.get('Customer').get('Account').get('CA_NAME')}"]})
        else:
            cust_row.update({'CA_ID': [None]})
            cust_row.update({'CA_TAX_ST': [None]})
            cust_row.update({'CA_B_ID': [None]})
            cust_row.update({'CA_NAME': [None]})

        # append to dataframe
        cust_df = pd.concat([cust_df, pd.DataFrame.from_dict(cust_row)], axis=0, ignore_index=True)

    cust_df.replace(to_replace=np.NaN, value="", inplace=True)
    cust_df.replace(to_replace="None", value="", inplace=True)
    cust_df.to_csv(csv_output_path, index=False)
    print('Customer Management data converted from XML to CSV')


# Provide your file paths
xml_file_path = r'C:\Users\ozanb\OneDrive\Masaüstü\scale5\Batch1\CustomerMgmt.xml'
json_output_path = r'C:\Users\ozanb\OneDrive\Masaüstü\scale5\Batch1\CustomerMgmt.json'
csv_output_path = r'C:\Users\ozanb\OneDrive\Masaüstü\scale5\Batch1\Customer.csv'

# Run the conversion
customermgmt_convert(xml_file_path, json_output_path, csv_output_path)
