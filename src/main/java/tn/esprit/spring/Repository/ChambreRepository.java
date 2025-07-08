package tn.esprit.spring.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import tn.esprit.spring.Entity.Chambre;

import java.util.List;

public interface ChambreRepository extends JpaRepository<Chambre, Long> {
    public List<Chambre> findByBlocFoyerUniversiteAdresseUniversite(String adress);
    public Chambre findByReservationEtudiantsCinAndBlocNomBloc(Long CIN, String nom);
}
