package tn.esprit.spring.Repository;

import org.springframework.data.jpa.repository.JpaRepository;
import tn.esprit.spring.Entity.Etudiant;

public interface EtudiantRepository extends JpaRepository<Etudiant, Long> {
}
