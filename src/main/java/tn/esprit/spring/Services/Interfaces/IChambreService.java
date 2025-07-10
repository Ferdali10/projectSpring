package tn.esprit.spring.Services.Interfaces;

import tn.esprit.spring.Entity.Chambre;

import java.util.List;

public interface IChambreService {
    
    // Modification de test pour le webhook Jenkins
    List<Chambre> retrieveAllChambres();
    
    Chambre addChambre(Chambre c);
    Chambre updateChambre (Chambre c);
    Chambre retrieveChambre (long idChambre);
    
}
