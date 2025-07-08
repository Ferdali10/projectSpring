package tn.esprit.spring.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import tn.esprit.spring.Entity.Universite;

public interface UniversiteRepository extends JpaRepository<Universite, Long> {

    public Universite findByFoyerCapaciteFoyerAndFoyerCapaciteFoyer(Long capaciteBloc,Long capaciteFoyer);
    public Universite findByNomUniversite(String nomUniversite);

}
