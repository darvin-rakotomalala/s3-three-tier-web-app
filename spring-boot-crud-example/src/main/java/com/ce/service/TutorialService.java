package com.ce.service;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ce.model.Tutorial;
import com.ce.repository.TutorialRepository;

@Service
public class TutorialService {

    private final TutorialRepository tutorialRepository;

    public TutorialService(TutorialRepository tutorialRepository) {
        this.tutorialRepository = tutorialRepository;
    }

    @Transactional(readOnly = true)
    public List<Tutorial> getAllTutorials(String title) {
        List<Tutorial> tutorials = new ArrayList<>();

        if (title == null) {
            tutorials.addAll(tutorialRepository.findAll());
        } else {
            tutorials.addAll(tutorialRepository.findByTitleContaining(title));
        }

        return tutorials;
    }

    @Transactional(readOnly = true)
    public Optional<Tutorial> getTutorialById(long id) {
        return tutorialRepository.findById(id);
    }

    @Transactional
    public Tutorial createTutorial(Tutorial tutorial) {
        // New tutorials are always created as unpublished
        return tutorialRepository.save(new Tutorial(tutorial.getTitle(), tutorial.getDescription(), false));
    }

    @Transactional
    public Optional<Tutorial> updateTutorial(long id, Tutorial tutorial) {
        return tutorialRepository.findById(id).map(existing -> {
            existing.setTitle(tutorial.getTitle());
            existing.setDescription(tutorial.getDescription());
            existing.setPublished(tutorial.isPublished());
            return tutorialRepository.save(existing);
        });
    }

    @Transactional
    public void deleteTutorial(long id) {
        tutorialRepository.deleteById(id);
    }

    @Transactional
    public void deleteAllTutorials() {
        tutorialRepository.deleteAll();
    }

    @Transactional(readOnly = true)
    public List<Tutorial> findPublishedTutorials() {
        return tutorialRepository.findByPublished(true);
    }
}
