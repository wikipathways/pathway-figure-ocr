import pandas as pd
import rpy2

import rpy2.robjects as robjects
from rpy2.robjects import pandas2ri
from rpy2.robjects.packages import importr

pandas2ri.activate()
base = importr("base")
readRDS = robjects.r["readRDS"]


def rdf2pandas(df):
    df_names = base.names(df)
    data = dict()
    for i in range(len(df_names)):
        column = df[i]
        if hasattr(column, "iter_labels"):
            data[df_names[i]] = [x for x in column.iter_labels()]
        else:
            data[df_names[i]] = [x for x in column]

    return pd.DataFrame(data=data)


def rds2pandas(f):
    return rdf2pandas(readRDS(str(f)))
