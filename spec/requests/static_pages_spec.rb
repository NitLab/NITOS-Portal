require 'spec_helper'

describe "Static pages" do

	let(:base_title) { "Nitos Experimental Portal" }

	describe "Home page" do

	    it "should have the content 'NITOS Portal'" do
	      visit root_path
	      expect(page).to have_content('NITOS Portal')
	    end

	    it "should have the base title" do
	      visit root_path
	      expect(page).to have_title("#{base_title}")
	    end

	    it "should not have a custom page title" do
	      visit root_path
	      expect(page).not_to have_title('| Home')
	    end
	end
 
  	describe "About page" do
	  	it "should have the content 'About Us'" do
	      visit about_path
	      expect(page).to have_content('About Us')
	    end

	    it "should have the title 'About Us'" do
	      visit about_path
	      expect(page).to have_title("#{base_title} | About Us")
	    end
  	end

  	describe "Your ssh keys page" do
	  	it "should have the content 'Your ssh keys'" do
	      visit your_ssh_keys_path
	      expect(page).to have_content('Your ssh keys')
	    end

	    it "should have the title 'Your ssh keys'" do
	      visit your_ssh_keys_path
	      expect(page).to have_title("#{base_title} | Your ssh keys")
	    end
  	end

  	describe "Node status page" do
	  	it "should have the content 'Node status'" do
	      visit node_status_path
	      expect(page).to have_content('Node status')
	    end

	    it "should have the title 'Node status'" do
	      visit node_status_path
	      expect(page).to have_title("#{base_title} | Node status")
	    end
  	end

  	describe "Scheduler page" do
	  	it "should have the content 'Scheduler'" do
	      visit scheduler_path
	      expect(page).to have_content('Scheduler')
	    end

	    it "should have the title 'Scheduler'" do
	      visit scheduler_path
	      expect(page).to have_title("#{base_title} | Scheduler")
	    end
  	end


end