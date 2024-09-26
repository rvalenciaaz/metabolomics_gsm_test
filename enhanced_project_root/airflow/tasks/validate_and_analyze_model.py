# tasks/validate_and_analyze_model.py

def validate_and_analyze_model(**kwargs):
    import cobra
    from db import session
    from models import AnalysisResults

    # Load the thermodynamically constrained model
    model = cobra.io.read_sbml_model('output/thermo_constrained_model.xml')

    # Perform FBA
    solution = model.optimize()

    # Perform FVA
    fva_results = cobra.flux_analysis.flux_variability_analysis(model)

    # Convert fluxes and FVA results to dictionaries
    fluxes_dict = solution.fluxes.to_dict()
    fva_dict = fva_results.to_dict()

    # Store results in the database
    analysis_result = AnalysisResults(
        objective_value=solution.objective_value,
        fluxes=fluxes_dict,
        fva_results=fva_dict
    )
    session.add(analysis_result)
    session.commit()
