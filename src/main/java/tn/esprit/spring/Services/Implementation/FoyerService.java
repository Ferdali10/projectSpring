package tn.esprit.spring.Services.Implementation;

import tn.esprit.spring.Entity.Foyer;
import tn.esprit.spring.Repository.FoyerRepository;
import tn.esprit.spring.Services.Interfaces.IFoyerService;

import java.util.List;

public class FoyerService implements IFoyerService {
    FoyerRepository foyerRepository;

    @Override
    public List<Foyer> retrieveAllFoyers() {
        return foyerRepository.findAll();
    }

    @Override
    public Foyer addFoyer(Foyer f) {
        return foyerRepository.save(f);
    }

    @Override
    public Foyer updateFoyer(Foyer f) {
        return foyerRepository.save(f);
    }

    @Override
    public Foyer retrieveFoyer(long idFoyer) {
        return foyerRepository.findById(idFoyer).orElse(null);
    }

    @Override
    public void removeFoyer(long idFoyer) {
        foyerRepository.deleteById(idFoyer);
    }
}
