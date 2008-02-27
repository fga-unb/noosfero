class FriendsBlock < ProfileListBlock

  def self.description
    _('A block that displays your friends')
  end

  def title
    _('Friends')
  end

  def footer
    owner_id = owner.identifier
    lambda do
      link_to _('All friends'), :profile => owner_id, :controller => 'profile', :action => 'friends'
    end
  end

  class FriendsBlock::Finder < ProfileListBlock::Finder
    def ids
      self.block.owner.friend_ids
    end
  end

  def profile_finder
    @profile_finder ||= FriendsBlock::Finder.new(self)
  end


end
