require File.expand_path('../../spec_helper', __FILE__)

module Bcsec
  describe User do
    before do
      @u = User.new("jo", :airport)
      @u.first_name = "Jocelyn"
      @u.last_name = "Jordan"
    end

    describe "#full_name" do
      it "works with both names" do
        @u.full_name.should == "Jocelyn Jordan"
      end

      it "uses the user name with no names" do
        @u.first_name = nil
        @u.last_name = nil
        @u.full_name.should == "jo"
      end

      it "works with just the last name" do
        @u.first_name = nil
        @u.full_name.should == "Jordan"
      end

      it "works with just the first name" do
        @u.last_name = nil
        @u.full_name.should == "Jocelyn"
      end
    end

    describe "#default_portal" do
      it "is always a symbol" do
        u = User.new('jo')
        u.default_portal = 'foo'
        u.default_portal.should == :foo
      end
    end

    describe "#portals" do
      it "is always an array" do
        User.new('J').portals.should == []
      end
    end

    describe "#may_access?" do
      it "permits access to a known portal" do
        @u.may_access?(:airport).should be_true
      end

      it "supports string-named portals" do
        @u.may_access?("airport").should be_true
      end

      it "refuses access to an unknown portal" do
        @u.may_access?(:seaport).should be_false
      end

      it "uses the default portal if available"
      it "fails without a portal if there's no default"
    end

    describe "#group_memberships" do
      it "is a Bcsec::GroupMemberships instance" do
        User.new('jo').group_memberships(:ENU).class.should == GroupMemberships
      end

      it "defaults to the groups for the default portal" do
        jo = User.new('jo')
        jo.default_portal = :ENU
        jo.group_memberships(:ENU) << GroupMembership.new(Group.new('Developer'))
        jo.group_memberships(:NOTIS) << GroupMembership.new(Group.new('Admin'))

        jo.group_memberships.include?('Developer').should be_true
        jo.group_memberships.include?('Admin').should be_false
      end

      it "locates a portal given as a string" do
        jo = User.new('jo')
        jo.group_memberships(:ENU) << GroupMembership.new(Group.new('Developer'))
        jo.group_memberships("ENU").size.should == 1
      end

      it "fails without the portal parameter if there's no default portal" do
        lambda { User.new('jo').group_memberships }.should raise_error(/No default portal/)
      end
    end

    describe "#merge!" do
      before do
        @a = User.new("jo")
        @b = User.new("jo")
      end

      it "modifies the target group in place" do
        @b.last_name = "Miller"
        @a.merge!(@b)
        @a.last_name.should == "Miller"
      end

      it "returns self" do
        @a.merge!(@b).object_id.should == @a.object_id
      end

      it "does not copy attributes which are already set" do
        @a.first_name = "Josephine"
        @b.first_name = "Jocelyn"
        @a.merge!(@b).first_name.should == "Josephine"
      end

      it "does not fail if reading an attribute throws an exception" do
        @b.should_receive(:first_name).and_throw("I don't know.  Leave me alone.")
        lambda { @a.merge!(@b) }.should_not raise_error
      end

      describe "of the default portal" do
        it "sets the target default portal if there isn't one already" do
          @b.default_portal = :ENU
          @a.merge!(@b)
          @a.default_portal.should == :ENU
        end

        it "leaves the default portal alone if it is already set" do
          @a.default_portal = :NOTIS
          @b.default_portal = :ENU
          @a.merge!(@b)
          @a.default_portal.should == :NOTIS
        end
      end

      describe "of portals" do
        before do
          @a.portals = [:ENU, :NOTIS]
          @b.portals = [:SQLSubmit, :ENU]
          @a.merge!(@b)
        end

        it "removes duplicates" do
          @a.portals.size.should == 3
        end

        it "includes portals that are in the source and target lists" do
          @a.may_access?(:ENU).should be_true
        end

        it "preserves portals that are only in the original list" do
          @a.may_access?(:NOTIS).should be_true
        end

        it "adds portals that are only in the new list" do
          @a.may_access?(:SQLSubmit).should be_true
        end

        it "works when the source portals are not set" do
          @b.portals = nil
          lambda { @a.merge!(@b) }.should_not raise_error
        end

        it "works when the target portals are not set" do
          @a.portals = nil
          lambda { @a.merge!(@b) }.should_not raise_error
          @a.portals.size.should == 2
        end
      end

      describe "of group memberships" do
        before do
          @a.group_memberships(:ENU) << GroupMembership.new(Group.new("User"))
        end

        it "adds memberships for a new portal" do
          @b.group_memberships(:NOTIS) << GroupMembership.new(Group.new("Admin"))
          @a.merge!(@b)
          @a.group_memberships(:NOTIS).include?("Admin").should be_true
        end

        it "does not merge group memberships when some are already known" do
          @b.group_memberships(:ENU) << GroupMembership.new(Group.new("Developer"))
          @a.merge!(@b)
          @a.group_memberships(:ENU).size.should == 1
        end
      end
    end
  end
end
