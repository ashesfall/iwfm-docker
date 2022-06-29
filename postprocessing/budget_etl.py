import sys
import os

from pywfm import IWFMBudget
import awswrangler as wr

def read_filename_from_commandline(args):
    """ Read the budget hdf file name from the commandline
    """
    if len(args) == 1:
        input("Provide name of budget HDF file: ")

    elif len(args) > 2:
        raise ValueError("Too many values provided on command line")

    else:
        file_name = args[1]
        if not os.path.exists(file_name):
            raise FileNotFoundError("File provided {} was not found".format(file_name))

        if not file_name.endswith('hdf'):
            raise ValueError("Budget files must be HDF format")

        return file_name

def date_to_water_year(month, year):
    if month > 9:
        return int(year + 1)
    else:
        return int(year)

if __name__ == '__main__':

    rz_budget_file = read_filename_from_commandline(sys.argv)

    data = None

    with IWFMBudget(rz_budget_file) as bud:
        locations = bud.get_location_names()

        for i, l in enumerate(locations, start=1):

            rz_annual = bud.get_values(
                i,
                output_interval='1YEAR',
                area_conversion_factor=1/43560,
                area_units='Acres',
                volume_conversion_factor=1/43560,
                volume_units='AF'
            )

            rz_annual['location_id'] = i
            rz_annual['location_name'] = l

            print(rz_annual.head())

            if data is None:
                data = rz_annual
            else:
                data.append(rz_annual)

    print(data.head)

    # Storing the data and metadata to Data Lake
    # wr.pandas.to_parquet(
    #     dataframe=data,
    #     database="database",
    #     path="s3://your-s3-bucket/path/to/new/table"
    #     # partition_cols=["name"],
    # )