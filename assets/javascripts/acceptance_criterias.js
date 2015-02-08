function AcceptanceCriteriaForm(data)
{
    var self = this;
    self.criterias = ko.observableArray(ko.utils.arrayMap(data, function(criteria) {
        return new AcceptanceCriteria(criteria);
    }));

    self.add = function() {
        self.criterias.push(new AcceptanceCriteria());
    };

    self.remove = function(criteria) {
        criteria.destroy(1);
    };
}

function AcceptanceCriteria(data)
{
    var self = this;
    self.id = data === undefined ? '' : ko.observable(data.id);
    self.title = data === undefined ? '' :  ko.observable(data.title);
    self.destroy = ko.observable(0);
}