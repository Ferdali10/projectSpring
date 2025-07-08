package tn.esprit.spring.Services.Implementation;

import tn.esprit.spring.Entity.Chambre;
import tn.esprit.spring.Repository.ChambreRepository;
import tn.esprit.spring.Services.Interfaces.IChambreService;

import java.util.List;

public class ChambreService implements IChambreService {
    ChambreRepository chambreRepository;
    @Override
    public List<Chambre> retrieveAllChambres() {
        return chambreRepository.findAll();
    }

    @Override
    public Chambre addChambre(Chambre c) {
        return chambreRepository.save(c);
    }

    @Override
    public Chambre updateChambre(Chambre c) {
        return chambreRepository.save(c);
    }

    @Override
    public Chambre retrieveChambre(long idChambre) {
        return chambreRepository.findById(idChambre).orElse(null);
    }
}
