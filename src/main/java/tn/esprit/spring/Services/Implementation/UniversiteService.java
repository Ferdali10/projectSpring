package tn.esprit.spring.Services.Implementation;

import tn.esprit.spring.Entity.Universite;
import tn.esprit.spring.Repository.UniversiteRepository;
import tn.esprit.spring.Services.Interfaces.IUniversiteService;

import java.util.List;

public class UniversiteService implements IUniversiteService {
    UniversiteRepository universiteRepository;

    @Override
    public List<Universite> retrieveAllUniversities() {
        return universiteRepository.findAll();
    }

    @Override
    public Universite addUniversite(Universite u) {
        return universiteRepository.save(u);
    }


    @Override
    public Universite updateUniversite(Universite u) {
        return universiteRepository.save(u);
    }

    @Override
    public Universite retrieveUniversite(long idUniversite) {
        return universiteRepository.findById(idUniversite).orElse(null);

    }


}
