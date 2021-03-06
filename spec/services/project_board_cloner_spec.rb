require "rails_helper"

describe ProjectBoardCloner do
  let(:instructor) { create(:instructor) }
  let(:student)    { create(:student, nickname: "ClassicRichard") }

  let(:project) {
    create(:project,
           name: "Brownfield of Dreams",
           user: instructor,
           project_board_base_url: "https://github.com/turingschool-examples/brownfield-of-dreams/projects/1"
          )
  }

  let(:clone) {
    create(:clone,
           students: "Richard H.",
           project: project,
           user: student
          )
  }

  let(:staff_client)   { Octokit::Client.new(access_token: instructor.token) }
  let(:student_client) { Octokit::Client.new(access_token: student.token) }

  let(:github_student)         { double(:github_user, login: "student") }
  let(:base_project_on_github) { double(:github_project, number: 1, id: 9999) }
  let(:forked_repo)            { double(:forked_repo, full_name: "student/brownfield-of-dreams", name: "brownfield-of-dreams", owner: github_student, full_path: "https://github.com/student/brownfield-of-dreams") }
  let(:cloned_project)         { double(:project, id: 1, html_url: "http://github.com/student/brownfield-of-dreams") }
  let(:invitation)             { double(:invitation, repository: forked_repo, id: 1234) }
  let(:column)                 { double(:column, name: "To Do") }

  subject { ProjectBoardCloner.new(project, clone, "student@example.com") }

  context "#run" do
    it "clones the repo while making the correct calls to Octokit" do
      allow(subject).to receive(:student_client).and_return(student_client)
      allow(subject).to receive(:staff_client).and_return(staff_client)

      expect(student_client).to receive(:fork).and_return(forked_repo)
      expect(student_client).to receive(:invite_user_to_repo)
      expect(student_client).to receive(:edit_repository).with("student/brownfield-of-dreams", has_issues: true)
      expect(student_client).to receive(:create_project).with("student/brownfield-of-dreams", "Brownfield of Dreams").and_return(cloned_project)

      expect(staff_client).to receive(:accept_repo_invitation)
      expect(staff_client).to receive(:user_repository_invitations).and_return([invitation])
      expect(staff_client).to receive(:projects).with("turingschool-examples/brownfield-of-dreams").and_return([base_project_on_github])
      expect(staff_client).to receive(:project_columns).with(9999).and_return([column])
      expect(ColumnCloner).to receive(:run!).with(column, forked_repo, "1", staff_client)
      expect(staff_client).to receive(:create_project_card)

      subject.run
    end
  end
end
