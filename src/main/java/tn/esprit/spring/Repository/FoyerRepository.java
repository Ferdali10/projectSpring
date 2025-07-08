package tn.esprit.spring.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import tn.esprit.spring.Entity.Foyer;
import tn.esprit.spring.Entity.TypeChambre;

public interface FoyerRepository extends JpaRepository<Foyer, Long> {
    public Foyer findByBlocChambreTypeCAndBlocNomBloc(TypeChambre typeChambre,String nomBloc);
}
