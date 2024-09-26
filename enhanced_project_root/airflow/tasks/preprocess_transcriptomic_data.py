# tasks/preprocess_transcriptomic_data.py

def preprocess_transcriptomic_data(**kwargs):
    import pandas as pd
    from db import session
    from models import TranscriptomicData
    import rpy2.robjects as ro
    from rpy2.robjects import pandas2ri

    pandas2ri.activate()

    # Load raw count data
    transcript_data = pd.read_csv('data/transcriptomic_counts.csv')

    # Advanced normalization using DESeq2
    ro.r('''
    library(DESeq2)
    normalize_counts <- function(count_data) {
        dds <- DESeqDataSetFromMatrix(countData = count_data, colData = data.frame(row.names=colnames(count_data)), design = ~ 1)
        dds <- estimateSizeFactors(dds)
        normalized_counts <- counts(dds, normalized=TRUE)
        return(normalized_counts)
    }
    ''')

    r_counts = pandas2ri.py2rpy(transcript_data.set_index('Gene_ID'))
    normalized_counts = ro.r['normalize_counts'](r_counts)
    normalized_counts_df = pandas2ri.rpy2py(normalized_counts)

    # Convert back to pandas DataFrame
    normalized_counts_df = pd.DataFrame(normalized_counts_df, index=transcript_data['Gene_ID'])
    normalized_counts_df.reset_index(inplace=True)
    normalized_counts_df.rename(columns={'index': 'Gene_ID'}, inplace=True)

    # Insert processed data into the database
    for _, row in normalized_counts_df.iterrows():
        data_entry = TranscriptomicData(
            gene_id=row['Gene_ID'],
            expression_value=row.iloc[1],  # Adjust index as necessary
            batch_id=row.get('Batch_ID', None)
        )
        session.add(data_entry)
    session.commit()
