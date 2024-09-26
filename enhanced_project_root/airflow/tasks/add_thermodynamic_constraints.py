# tasks/add_thermodynamic_constraints.py

def add_thermodynamic_constraints(**kwargs):
    import cobra
    from pytfa import ThermodynamicModel
    from pytfa.io import load_thermoDB

    # Load the model
    model = cobra.io.read_sbml_model('output/prom_integrated_model.xml')

    # Load thermodynamic data
    thermo_data = load_thermoDB('data/thermo_data.tsv')

    # Convert to ThermodynamicModel
    tmodel = ThermodynamicModel(thermo_data, model)
    tmodel.prepare()
    tmodel.convert()

    # Optimize the thermodynamically constrained model
    solution = tmodel.optimize()

    # Save the model
    tmodel.solver.update()
    cobra.io.write_sbml_model(tmodel, 'output/thermo_constrained_model.xml')
