# metabolic_workflow_dag.py

from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from datetime import datetime, timedelta

# Import task functions
from tasks.preprocess_exometabolomic_data import preprocess_exometabolomic_data
from tasks.preprocess_transcriptomic_data import preprocess_transcriptomic_data
from tasks.map_metabolites import map_metabolites
from tasks.map_genes_and_reactions import map_genes_and_reactions
from tasks.integrate_data_into_model import integrate_data_into_model
from tasks.integrate_with_PROM import integrate_with_PROM
from tasks.add_thermodynamic_constraints import add_thermodynamic_constraints
from tasks.validate_and_analyze_model import validate_and_analyze_model
from tasks.validate_with_phenotypic_data import validate_with_phenotypic_data
from tasks.perform_cross_validation import perform_cross_validation
from tasks.visualize_and_report import visualize_and_report

# Default arguments for the DAG
default_args = {
    'owner': 'your_name',
    'depends_on_past': False,
    'email': ['your_email@example.com'],
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# Define the DAG
dag = DAG(
    'metabolic_workflow',
    default_args=default_args,
    description='Enhanced workflow for metabolic model integration using Airflow',
    schedule_interval=None,
    start_date=datetime(2023, 1, 1),
    catchup=False,
)

# Define tasks
preprocess_exo_task = PythonOperator(
    task_id='preprocess_exometabolomic_data',
    python_callable=preprocess_exometabolomic_data,
    dag=dag,
)

preprocess_transcript_task = PythonOperator(
    task_id='preprocess_transcriptomic_data',
    python_callable=preprocess_transcriptomic_data,
    dag=dag,
)

map_metabolites_task = PythonOperator(
    task_id='map_metabolites',
    python_callable=map_metabolites,
    dag=dag,
)

map_genes_task = PythonOperator(
    task_id='map_genes_and_reactions',
    python_callable=map_genes_and_reactions,
    dag=dag,
)

integrate_data_task = PythonOperator(
    task_id='integrate_data_into_model',
    python_callable=integrate_data_into_model,
    op_kwargs={'algorithm': 'init'},  # You can specify 'fastcore' or other algorithms
    dag=dag,
)

integrate_PROM_task = PythonOperator(
    task_id='integrate_with_PROM',
    python_callable=integrate_with_PROM,
    dag=dag,
)

add_thermo_constraints_task = PythonOperator(
    task_id='add_thermodynamic_constraints',
    python_callable=add_thermodynamic_constraints,
    dag=dag,
)

validate_analyze_task = PythonOperator(
    task_id='validate_and_analyze_model',
    python_callable=validate_and_analyze_model,
    dag=dag,
)

validate_phenotype_task = PythonOperator(
    task_id='validate_with_phenotypic_data',
    python_callable=validate_with_phenotypic_data,
    dag=dag,
)

cross_validation_task = PythonOperator(
    task_id='perform_cross_validation',
    python_callable=perform_cross_validation,
    dag=dag,
)

visualize_report_task = PythonOperator(
    task_id='visualize_and_report',
    python_callable=visualize_and_report,
    dag=dag,
)

# Set task dependencies
preprocess_exo_task >> preprocess_transcript_task >> map_metabolites_task >> map_genes_task >> integrate_data_task >> integrate_PROM_task >> add_thermo_constraints_task >> validate_analyze_task >> [validate_phenotype_task, cross_validation_task] >> visualize_report_task
